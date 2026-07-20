# 🎤 Rollouts, Helm/Kustomize & GitOps Incidents
**7 Slides · ConfigMap Reload, Helm 3-Way Merge, Kustomize Generators, Helm Hooks, CRD/Operator Health, Conversion Webhooks**

---

# 🔴 Slide 1 · Scenario: ConfigMap Update Never Picked Up

**🏗️ Setup**
> *An engineer updates a ConfigMap with a new `LOG_LEVEL` and a corrected upstream URL, waits well past any reasonable sync interval, and the running pods are still logging with the old config — no errors, no events, nothing.*

**❓ The Question**
You updated a ConfigMap an hour ago and the app is still using stale config. Nothing in `kubectl describe pod` looks wrong. Walk me through your diagnosis.

```
$ kubectl get configmap app-config -o jsonpath='{.data.LOG_LEVEL}'
debug
$ kubectl exec -it app-7f8c9d-x2k4l -- cat /etc/app/config/app.properties
LOG_LEVEL=info    # ← still the old value, an hour later
```

**🔍 Diagnosis**
1. Confirm it's actually a volume mount, not an env var (`env`/`envFrom` *never* live-update — that's a restart, not a bug)
2. Check whether the volumeMount uses `subPath` — this is the #1 cause of "ConfigMap changed but pod never sees it"
3. `subPath` bind-mounts a single file directly out of the source volume, so there's no directory-level symlink for kubelet to atomically swap — the file is frozen at whatever content existed when the pod started, permanently, until the pod itself is recreated
4. Confirm with the pod spec directly, not by guessing

**✅ Fix**
```bash
# Step 1: confirm the mount type — this is the smoking gun
kubectl get pod app-7f8c9d-x2k4l -o yaml | grep -A5 subPath
#         - mountPath: /etc/app/config/app.properties
#           name: config-volume
#           subPath: app.properties   # ← there it is: symlink-swap mechanism is bypassed entirely
```

```yaml
# Option A (preferred): stop using subPath — mount the whole directory instead
volumes:
  - name: config-volume
    configMap:
      name: app-config
containers:
  - volumeMounts:
      - name: config-volume
        mountPath: /etc/app/config   # ← whole directory, no subPath key at all
        # kubelet now does the normal atomic symlink swap on ConfigMap change

# Option B: if you truly must keep subPath (e.g. avoid clobbering an existing dir),
# force a rollout on every change instead of relying on live-update
spec:
  template:
    metadata:
      annotations:
        checksum/config: "{{ include (print $.Template.BasePath \"/configmap.yaml\") . | sha256sum }}"
        # ← any content change alters this annotation, which changes the pod template,
        #   which triggers a normal rolling update — sidesteps subPath entirely by restarting
```

```bash
# Option C: no chart involved — let Reloader watch and restart for you
kubectl annotate deployment web reloader.stakater.com/auto="true"
```

**🛡️ Prevention**
- Default to whole-directory volume mounts; only reach for `subPath` when you must avoid overwriting an existing directory, and treat that as "requires a restart to update" going in
- Wire a checksum annotation (Helm) or Reloader into every Deployment that mounts a ConfigMap/Secret expected to change at runtime
- See `../Components/ConfigMapSecret/ConfigMapSecret.md` — the Auto-Reload Gotcha section has the full mechanism, including why plain volume mounts *do* eventually update (~1 min, atomic symlink swap) while `subPath` structurally cannot

> ⚠️ **Never:** Assume "it just needs more time" once you've confirmed `subPath` is in play — there is no sync interval that fixes this; only a pod restart (or removing `subPath`) does.

---

# 🔴 Slide 2 · Scenario: `helm upgrade` Silently Reverts a Manual Annotation

**🏗️ Setup**
> *An engineer ran `kubectl annotate deployment web internal.company/owned-by=platform-team` on a live resource to satisfy an internal inventory tool. Weeks later, a routine `helm upgrade` runs, the annotation vanishes, and the inventory tool starts paging about an "unowned" resource.*

**❓ The Question**
Why would a `helm upgrade` remove an annotation nobody told it to touch, and what should have been done instead?

**🔍 Diagnosis**
1. `helm upgrade` is not a naive "apply new manifest over old" — it computes a **3-way strategic merge** across (a) Helm's own last-recorded release manifest, (b) the live object's actual current state, and (c) the freshly rendered manifest from the new chart/values
2. The manually added annotation exists only in (b) — it was never part of (a), because Helm never put it there
3. From Helm's perspective, anything present in live state but absent from both its own history *and* the new render is out-of-band drift — but the key nuance here is different: Helm reconciles the object to match (c) for every field (c) actually manages; an annotation nobody templated is not "protected" just because it's manual — whether it survives depends on whether the new render's metadata section replaces the whole annotations map or merges into it
4. In practice, many charts template `metadata.annotations` as a whole map (`{{ toYaml .Values.podAnnotations }}` or similar) — when Helm patches, it's not deleting *your* annotation surgically, it's asserting the full annotations set it *thinks* it owns, and unmanaged keys outside that set get squeezed out on the next full-object PATCH depending on how the field is rendered
5. Confirm by diffing the chart's rendered manifest against the live object before the upgrade happened

**✅ Fix**
```bash
# Confirm what Helm actually thinks the previous state was
helm get manifest web -n production | grep -A10 "annotations:"

# Confirm what's live right now
kubectl get deployment web -n production -o yaml | grep -A10 "annotations:"

# Dry-run the next upgrade to see exactly what would be patched, before it happens
helm upgrade web ./web-chart -f values-prod.yaml --dry-run --debug | diff - <(kubectl get deployment web -n production -o yaml)
```

```yaml
# CORRECT pattern: put anything that needs to persist into the chart's values, not a manual kubectl annotate
# values-prod.yaml
podAnnotations:
  internal.company/owned-by: "platform-team"   # ← now Helm renders and OWNS this annotation every upgrade
```

```yaml
# templates/deployment.yaml — chart must actually template it for this to work
metadata:
  annotations:
    {{- toYaml .Values.podAnnotations | nindent 4 }}
```

**🛡️ Prevention**
- Never hand-edit a Helm-managed resource with `kubectl annotate`/`kubectl edit`/`kubectl patch` — anything that matters must go through the chart/values so it survives the next `helm upgrade`
- Run `helm diff upgrade` (helm-diff plugin) or `--dry-run --debug` before every production upgrade to catch exactly this class of surprise before it ships
- If a field genuinely needs to be managed by something other than Helm (e.g. an external controller stamping status), don't put it under Helm's ownership at all — keep it on a separate object or a field Helm's templates never touch

> ⚠️ **Never:** Treat "Helm didn't complain" as proof nothing changed — Helm's 3-way merge will silently reconcile away anything it considers drift from what its own chart renders, with no warning, no diff shown by default, and no confirmation prompt. See `../Components/Helm/Helm.md`'s 3-Way Strategic Merge section for the full mechanism.

---

# 🔴 Slide 3 · Scenario: Kustomize `configMapGenerator` Confuses the Team

**🏗️ Setup**
> *Engineer A edits `overlays/prod/kustomization.yaml`'s `configMapGenerator` literals, runs `kubectl apply -k`, and is confused why pods didn't restart. Engineer B, frustrated waiting, runs `kubectl edit configmap app-config-8f2a1c` directly to "just fix it now" — and the next `kubectl apply -k` from CI wipes their edit out completely with no warning.*

**❓ The Question**
Explain what's actually going on here and what the correct mental model is for both engineers.

```
$ kubectl get configmap -n production
NAME                    DATA   AGE
app-config-8f2a1c        2      3d     # ← hash-suffixed, not "app-config"
```

**🔍 Diagnosis**
1. `configMapGenerator` generates a **new object with a content-hash suffix** on every build — `app-config-8f2a1c` today, `app-config-3d9e71` if the literals change tomorrow — never an in-place edit of an existing object
2. Kustomize also rewrites every reference to that ConfigMap elsewhere in the same kustomization (`envFrom`, `configMapKeyRef`, `volumes.configMap.name`) to point at the new hashed name automatically
3. That reference rewrite **is** a pod template change — the Deployment's spec now genuinely differs — so the normal rolling-update mechanism fires with zero extra hooks or checksum tricks
4. Engineer B's `kubectl edit configmap app-config-8f2a1c` edited a generated, disposable artifact — not the source of truth. The source of truth is the `literals:`/`files:` in `kustomization.yaml`. The next `kubectl apply -k` re-derives the object from source and overwrites the manual edit, because from Kustomize's perspective the manual edit never happened — it isn't tracked anywhere in git
5. Engineer A's confusion is the mirror image: they DID edit the real source, but if the literal value didn't actually change (e.g. re-applied the same value, or edited a comment/whitespace only) the hash doesn't change, so no new object is generated and no rollout fires — this is correct, not broken

**✅ Fix**
```yaml
# overlays/prod/kustomization.yaml — THIS is the source of truth, not the generated ConfigMap
configMapGenerator:
  - name: app-config
    behavior: merge
    literals:
      - LOG_LEVEL=warn        # ← edit HERE, not via kubectl edit on the generated object
      - FEATURE_X=enabled
```

```bash
# Verify the mental model end to end
kubectl kustomize overlays/prod | grep -A2 "kind: ConfigMap"        # ← see the new hash before applying
kubectl kustomize overlays/prod | grep "configMapRef\|name: prod-app-config"  # ← confirm rewritten refs

kubectl apply -k overlays/prod
kubectl rollout status deployment/prod-web -n production   # ← rollout happens automatically, driven by the name change
```

**🛡️ Prevention**
- Establish as a team norm: **generated ConfigMaps are build artifacts, not editable objects** — the only legitimate edit surface is the `kustomization.yaml` source (or the files it references)
- Add a pre-merge CI check that runs `kubectl diff -k overlays/prod` so reviewers see the actual generated diff (including the new hash) before it merges, closing the gap between "I changed a literal" and "I understand what will roll out"
- Consider `immutable: true` on generated ConfigMaps — since content changes always produce a new object anyway, this is free and prevents any future `kubectl edit` from silently succeeding-then-being-overwritten; it fails loudly instead

> ⚠️ **Never:** Let a team "fix it in prod" with `kubectl edit` on any Kustomize-generated or Helm-managed object — GitOps only works if the git source and live cluster state have exactly one path of truth; a direct edit creates a second one that the next sync silently erases, or worse, drifts from without anyone noticing. See `../Components/Kustomize/Kustomize.md`'s `configMapGenerator` section for the full hash-suffix mechanism.

---

# 🔴 Slide 4 · Scenario: `helm upgrade` Hangs on a Failed `pre-upgrade` Hook

**🏗️ Setup**
> *A routine `helm upgrade` for a schema migration release never returns — it sits for several minutes, then fails outright. The release is now in a stuck state and a second attempt fails immediately with a different error.*

**❓ The Question**
Walk me through diagnosing and recovering from this.

```
$ helm upgrade api-server ./api-server -f values-prod.yaml
Error: UPGRADE FAILED: pre-upgrade hooks failed: job failed: BackoffLimitExceeded

$ helm upgrade api-server ./api-server -f values-prod.yaml
Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
```

**🔍 Diagnosis**
1. `helm` itself never shows *application-level* failures — it only reports that the Job hit `BackoffLimitExceeded` (all retries exhausted), not why the container inside it failed
2. Go straight to the hook Job's pod logs — that's where the real error lives
3. The second error is the operational consequence: the failed upgrade left the release stuck in `pending-upgrade` state in Helm's own history (a Secret), and Helm refuses to start a new operation on top of an unfinished one
4. Because `pre-upgrade` hooks run **before** the main Deployment is touched, the app itself is very likely untouched and still running the old version — this is usually not a live outage, but the pipeline is blocked

**✅ Fix**
```bash
# Step 1: the actual error is in the Job's pod, not in helm's output
kubectl get pods -n production -l job-name=db-migration-hook
kubectl logs job/db-migration-hook -n production
# Error: migration 0042_add_index.sql failed: could not obtain lock on relation "orders"
# ← e.g. a long-running transaction was blocking the migration's DDL lock

# Step 2: confirm the release is stuck
helm history api-server -n production
# REVISION  STATUS            CHART              APP VERSION
# 12        pending-upgrade    api-server-1.5.0   2.2.0   ← stuck here

# Step 3a: recover by rolling back the stuck release to the last known-good revision
helm rollback api-server 11 -n production

# Step 3b: OR fix forward — resolve the underlying DB issue, then clean up the failed
# hook Job (it won't be recreated automatically because Job specs are immutable)
kubectl delete job db-migration-hook -n production
helm upgrade api-server ./api-server -f values-prod.yaml   # re-run once the blocker is cleared
```

```yaml
# templates/migration-job.yaml — ensure this is set BEFORE you hit this incident, not after
metadata:
  annotations:
    helm.sh/hook: pre-upgrade,pre-install
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
    # ← before-hook-creation deletes the stale Job automatically on the NEXT attempt,
    #   since a Job's spec is immutable and a leftover Job with the same name
    #   would otherwise make the retry fail before it even starts
```

**🛡️ Prevention**
- Always set `helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded` on hook Jobs so retries aren't blocked by a Job that can't be replaced in place
- Test migration scripts against a realistic copy of production data/load in staging — lock contention and long-running transactions are the most common real-world cause of migration hook failures
- Treat `pending-upgrade`/`pending-install` release states as a signal to investigate immediately, not to retry blindly — `helm history` should be the first command run, before any retry

> ⚠️ **Never:** Force through a stuck release with `helm upgrade --force` without first understanding why the hook failed — you can end up applying a new chart version on top of a release Helm itself considers mid-upgrade, and if the migration was partially applied, retrying it blind can double-apply non-idempotent DDL. See `../Components/Helm/Helm.md`'s Hooks section for the full hook lifecycle and delete-policy semantics.

---

# 🔴 Slide 5 · Scenario: A CRD's Custom Resources Never Get a Status

**🏗️ Setup**
> *A team applies a `Certificate` custom resource for a new domain. `kubectl apply` returns success immediately. Days later, no TLS certificate has ever been issued, `status.conditions` on the object is completely empty, and nothing in `kubectl describe` hints at why.*

**❓ The Question**
`kubectl apply` succeeded with no error — so why is nothing happening?

**🔍 Diagnosis**
1. Remember the core fact: a CRD alone is completely inert — it's a schema registration that lets objects land in etcd, nothing more. `kubectl apply` succeeding only proves the object passed schema validation and was stored; it proves nothing about whether anything is watching it
2. Check whether the controller/operator is even running at all — this is step one, before looking at the CR itself any further
3. If the pod is running, check its logs for reconcile errors on this specific object/namespace
4. Check RBAC — the operator's ServiceAccount needs permission to `get/list/watch` the CRD's objects and to `update` their `status` subresource, plus whatever permissions it needs on the resources it manages (Secrets, in cert-manager's case)
5. Compare `metadata.generation` vs `status.observedGeneration` if status exists at all but looks stale — an empty status from the start points at the controller never having reconciled this object even once

**✅ Fix**
```bash
# Step 1: is the operator pod even running?
kubectl get pods -n cert-manager
# NAME                                      READY   STATUS             RESTARTS
# cert-manager-6d4b9f8c7d-x2k9p             0/1     CrashLoopBackOff   14
# ← there it is — the controller isn't running at all, so nothing was ever watching

# Step 2: check why it's crashing
kubectl logs -n cert-manager deploy/cert-manager -f --previous
# error: failed to list *v1.Certificate: certificates.cert-manager.io is forbidden:
# User "system:serviceaccount:cert-manager:cert-manager" cannot list resource
# "certificates" in API group "cert-manager.io" at the cluster scope

# Step 3: confirm the RBAC gap directly
kubectl get clusterrole cert-manager-controller-issuers -o yaml | grep -A5 "certificates.cert-manager.io"
```

```yaml
# Fix: the operator's ClusterRole must actually grant watch/list/update on its own CRDs
# AND the status subresource specifically (a common thing to forget)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cert-manager-controller-issuers
rules:
  - apiGroups: ["cert-manager.io"]
    resources: ["certificates", "certificaterequests"]
    verbs: ["get", "list", "watch", "create", "update", "delete"]
  - apiGroups: ["cert-manager.io"]
    resources: ["certificates/status"]     # ← status is a separate subresource — separate RBAC rule required
    verbs: ["update", "patch"]
```

```bash
# Once the operator is healthy again, confirm reconciliation actually resumed
kubectl describe certificate api-tls-cert -n production
# Look specifically for status.conditions with a Ready condition and a reason/message —
# an object that STILL shows no status.conditions after the operator is confirmed healthy
# means it's specifically not reconciling THIS object/namespace (check controller's
# namespace-scoping / label selectors next)
```

**🛡️ Prevention**
- Alert on operator/controller Deployment health directly (`kubectl get pods` readiness, restart counts) — don't rely on discovering the outage via "customer's cert expired"
- Alert on CR objects with `status.conditions` empty or stale for longer than one reconcile interval — a purely declarative signal that something is inert
- When installing any operator via Helm, remember CRDs in `crds/` are applied once at install time only and never touched by `helm upgrade` — verify the CRD schema in-cluster matches what the new controller version expects before assuming an RBAC or controller-liveness issue

> ⚠️ **Never:** Assume "the object exists in `kubectl get`" means anything is happening with it — that only proves the API server accepted and stored it. See `../Components/CRD/CustomResourcesCRD.md`'s "A CRD Is Completely Inert" section — the CRD + controller pairing is the entire operator pattern, and either half missing produces exactly this silent-nothing-happens symptom.

---

# 🔴 Slide 6 · Scenario: Conversion Webhook Unreachable Breaks One CRD Version

**🏗️ Setup**
> *A CRD serves both `v1beta1` (legacy clients) and `v1` (current) with a webhook conversion strategy, since the schema changed shape between versions. `kubectl get widgets.example.com/v1beta1` suddenly starts failing for everyone still on the old version, while `v1` clients are unaffected — or is it the other way around, depending which version is the storage version.*

**❓ The Question**
Explain exactly what's failing here and why it only affects this CRD and not, say, a Deployment or a single-version CRD.

```
$ kubectl get widgets my-widget -o yaml
Error from server: conversion webhook for example.com/v1, Kind=Widget failed:
Post "https://widget-webhook.example-system.svc:443/convert": no endpoints available
```

**🔍 Diagnosis**
1. This CRD has more than one `served` version, and the two schemas differ enough (a renamed/restructured field) that the `None` conversion strategy can't safely translate between them — so it's configured with `strategy: Webhook`
2. Every read/write of a non-storage version has to round-trip through that webhook to be converted to/from whatever version etcd actually persists (`storage: true`)
3. "no endpoints available" means the webhook's backing `Service` has zero healthy pods behind it — check the Deployment fronting that Service directly
4. This failure mode is structurally specific to multi-version-with-webhook-conversion CRDs: a single-version CRD, or a multi-version CRD using `None` strategy, has no conversion step in the read/write path at all, so there's nothing to fail — the object is just returned as stored, unchanged
5. Conversions fail closed by design — an unreachable webhook doesn't silently skip conversion and return possibly-wrong data, it errors the entire request

**✅ Fix**
```bash
# Step 1: confirm the webhook's Service has no healthy backing pods
kubectl get endpoints widget-webhook -n example-system
# NAME             ENDPOINTS   AGE
# widget-webhook   <none>      12m    # ← confirms "no endpoints available"

kubectl get pods -n example-system -l app=widget-webhook
# NAME                             READY   STATUS             RESTARTS
# widget-webhook-7d9c8f6b5-k2m1p   0/1     CrashLoopBackOff   8

# Step 2: check why the webhook pod itself is down
kubectl logs -n example-system deploy/widget-webhook --previous
# e.g. TLS cert expired, bad config, OOMKilled — treat like any other Deployment outage

# Step 3: once the fix is identified, restore the Deployment to healthy
kubectl rollout restart deployment/widget-webhook -n example-system
kubectl rollout status deployment/widget-webhook -n example-system

# Step 4: confirm conversion path is restored
kubectl get widgets.v1beta1.example.com my-widget -o yaml   # should now succeed
```

```yaml
# CRD's conversion config for reference — this is what's routing through the broken webhook
spec:
  conversion:
    strategy: Webhook
    webhook:
      clientConfig:
        service:
          name: widget-webhook        # ← same Service that's showing zero endpoints above
          namespace: example-system
          path: /convert
      conversionReviewVersions: ["v1"]
```

**🛡️ Prevention**
- Treat the conversion webhook Deployment as tier-1 infrastructure, not an implementation detail — its outage silently breaks `kubectl get/apply` for an entire CRD version across every consumer, with no gradual degradation
- Run at least 2 replicas with a PodDisruptionBudget and readiness probes on any conversion webhook — a single-pod webhook is a guaranteed multi-version-CRD outage during any node drain or rolling update
- Prefer `None` conversion strategy whenever the schema change is genuinely additive/compatible — every webhook you avoid needing is one less thing that can go down and take API access with it

> ⚠️ **Never:** Assume a CRD conversion failure is "just this one object" — it affects every read/write of every object of the non-storage version cluster-wide the moment the webhook goes unreachable, since conversion isn't optional once configured — it's mandatory on every access of that version. See `../Components/CRD/CustomResourcesCRD.md`'s Multi-Version CRDs section for the full `served`/`storage`/conversion mechanics.

---

# 🎤 Slide 7 · Follow-up Q&A

---

### Q: Helm vs Kustomize — when would you reach for each in a real GitOps pipeline?
- Reach for **Helm** when you're distributing or consuming genuinely configurable, reusable software — third-party/community charts (ingress-nginx, cert-manager, Prometheus Operator) are the default form these ship in, and you get packaging (OCI/chart repos), versioning, and `helm rollback` history for free
- Reach for **Kustomize** when you own the manifests yourself and just need per-environment variation (replica counts, image tags, a resource patch) on top of otherwise-identical YAML — no templating dialect to introduce, and every file stays independently valid, applyable YAML
- The common enterprise pattern is both together: `helm template chart | kustomize build -` (or ArgoCD's native `kustomize` post-renderer on a Helm source) — Helm handles what the chart author already parameterized, Kustomize patches the handful of things they didn't, without forking the chart
- In a GitOps controller (ArgoCD `Application.spec.source`, Flux `HelmRelease`/`Kustomization`), both are first-class source types — the git repo is the single source of truth either way, and a revert is always `git revert` + reconcile, not a tool-specific rollback

> 💬 **Say:** "Helm solves distributing configurable software; Kustomize solves taking manifests you already own and adjusting them per environment without inventing a templating language. In practice I use Helm for anything I'm consuming from outside the team, and Kustomize overlays on top when the chart's values.yaml doesn't expose the one field I need to tweak."

---

### Q: How do you debug a stuck or failed Helm release in production without making it worse?
- First command, always: `helm history <release> -n <namespace>` — confirms the exact state (`pending-upgrade`, `pending-install`, `failed`) before touching anything, since the recovery path differs by state
- Never blindly retry or `--force` a stuck upgrade — check the actual failure first: for hook failures, go straight to `kubectl logs job/<hook-job-name>` since Helm's own error only reports the Job's outcome (`BackoffLimitExceeded`), never the application-level cause inside it
- Use `helm get manifest` / `helm get values --all` to see exactly what Helm believes it last applied, and diff that against live state (`kubectl get ... -o yaml`) before deciding whether to roll back or fix forward
- `helm rollback <release> <revision>` is almost always the safest first move if the app-facing impact is live — it returns to a known-good manifest immediately; only fix-forward (resolve the root cause, delete any stuck hook Job per its `hook-delete-policy`, re-run `helm upgrade`) when rolling back would leave data in a worse state (e.g. a partially applied, non-idempotent migration)
- Use `--dry-run --debug` before any retry — it submits a real server-side dry run and will surface CRD/webhook/admission problems that a blind retry would only discover by failing again

> 💬 **Say:** "The first thing I run is `helm history`, not a retry — the recovery path is completely different depending on whether the release is `pending-upgrade` versus cleanly `failed`. And for hook failures specifically, Helm's own error message is basically useless; the real answer is always in the hook Job's pod logs."

---

### Q: Your CRD's custom resources show no status and the object seems fine — what's your triage order?
1. Confirm the controller/operator pod is actually running (`kubectl get pods -n <operator-namespace>`) — a CRD is completely inert without a controller watching it, so this is checked before looking at the CR again at all
2. If the pod is running, check its logs for reconcile errors scoped to this object's namespace/name specifically, not just that the pod is "Ready"
3. Check the operator ServiceAccount's RBAC — specifically both the base resource verbs (`get/list/watch/update`) **and** the `<resource>/status` subresource, which needs its own separate rule and is the single most common thing left out
4. Compare `metadata.generation` to `status.observedGeneration` — if generation has moved past observedGeneration, the controller is alive but hasn't caught up to the latest spec edit yet; that's a lag, not a total outage

> 💬 **Say:** "Empty status forever, not just briefly, is the tell that nobody's reconciling this object — so my first move is always to check whether the controller pod is even running, before I spend any time interpreting the CR itself."

---
