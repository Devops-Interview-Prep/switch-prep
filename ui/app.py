#!/usr/bin/env python3
"""Switch Prep UI — DevOps Interview Notes Manager"""

from flask import Flask, request, jsonify, send_from_directory
import os
from pathlib import Path

app = Flask(__name__, static_folder="static")

NOTES_ROOT = Path(__file__).parent.parent.resolve()
EXCLUDED = {".git", "__pycache__", "node_modules", "ui", ".DS_Store", ".idea", ".vscode", ".claude"}
VIEW_EXTS = {".md", ".txt", ".go", ".py", ".sh", ".yaml", ".yml", ".json"}

# Expected topics per category for gap analysis
EXPECTED_TOPICS = {
    "Kubernetes": [
        "RBAC", "NetworkPolicy", "HPA", "VPA", "Ingress", "Helm",
        "Kustomize", "Resource Quotas", "Pod Disruption Budget",
        "Taints & Tolerations", "Node Affinity", "Security Context",
        "Admission Webhooks", "Custom Resources CRD", "OPA Gatekeeper",
    ],
    "AWS": [
        "EKS", "Lambda", "CloudWatch", "CloudFormation", "Systems Manager",
        "Cost Explorer", "Transit Gateway", "GuardDuty", "Control Tower",
        "PrivateLink", "Service Quotas",
    ],
    "Terraform": [
        "Remote Backend", "State Locking", "Import", "Drift Detection",
        "Terratest", "Sentinel Policy", "CDK for Terraform",
    ],
    "Docker": [
        "Security Best Practices", "Multi-stage Builds", "Networking Modes",
        "Volume Management", "Resource Limits", "Distroless Images",
    ],
    "Networking": [
        "BGP", "iptables rules", "eBPF", "Service Mesh Istio",
        "mTLS", "cert-manager", "VXLAN",
    ],
    "Linux & OS": [
        "cgroups v2", "eBPF", "Performance Tuning", "SELinux AppArmor",
        "inotify", "sysctl Kernel Parameters", "systemd units",
    ],
    "ArgoCD": [
        "App of Apps Pattern", "ApplicationSet", "Sync Waves Hooks",
        "RBAC ArgoCD", "Argo Notifications", "Argo Rollouts Canary",
    ],
    "Techs": [
        "Incident Response", "Postmortem Culture", "Chaos Engineering",
        "Game Days", "Toil Reduction", "Error Budget Policy",
        "Cost Optimization", "GitOps patterns",
    ],
    "Tools": [
        "Prometheus Internals", "PromQL queries", "Alertmanager routing",
        "Grafana Dashboards", "Loki LogQL", "OpenTelemetry",
        "Distributed Tracing", "Falco Runtime Security",
    ],
}


def note_status(content: str) -> str:
    stripped = content.strip()
    if not stripped:
        return "empty"
    content_lines = [
        l for l in stripped.split("\n")
        if l.strip() and not l.startswith("#") and not l.startswith("---")
    ]
    if len(content_lines) < 3 or len(stripped) < 200:
        return "incomplete"
    return "complete"


def score_note(content: str) -> dict:
    """Score a markdown note 0–10 and surface improvement issues."""
    stripped = content.strip()
    if not stripped:
        return {
            "score": 0, "grade": "F",
            "issues": ["File is completely empty — needs content"],
            "strengths": [], "words": 0, "code_blocks": 0, "sections": 0,
        }

    score = 0
    issues = []
    strengths = []
    lines = stripped.split("\n")
    words = len(stripped.split())

    # 1. Word count (0–2 pts)
    if words >= 500:
        score += 2
        strengths.append(f"Comprehensive depth ({words:,} words)")
    elif words >= 200:
        score += 1
    else:
        issues.append(f"Too brief — only {words} words (aim for 200+)")

    # 2. Structure / headings (0–2 pts)
    h2 = sum(1 for l in lines if l.startswith("## "))
    h3 = sum(1 for l in lines if l.startswith("### "))
    if h2 >= 4:
        score += 2
        strengths.append(f"Well-structured ({h2} sections, {h3} subsections)")
    elif h2 >= 2:
        score += 1
    else:
        issues.append("Add ## section headings to structure the content")

    # 3. Code examples (0–2 pts)
    code_blocks = content.count("```") // 2
    if code_blocks >= 3:
        score += 2
        strengths.append(f"{code_blocks} code/command examples")
    elif code_blocks >= 1:
        score += 1
    else:
        issues.append("Add code blocks (``` commands, configs, YAML examples)")

    # 4. Real-world examples (0–1 pt)
    has_examples = any(
        kw in content.lower()
        for kw in ["example", "e.g.", "scenario", "for instance", "use case", "real-world"]
    )
    if has_examples:
        score += 1
        strengths.append("Includes real-world examples")
    else:
        issues.append("Add real-world examples or use cases")

    # 5. Interview coverage (0–1 pt)
    q_count = sum(1 for l in lines if l.strip().endswith("?"))
    has_interview = any(
        kw in content.lower()
        for kw in ["interview", "common question", "asked in", "q:"]
    )
    if has_interview or q_count >= 3:
        score += 1
        strengths.append("Covers interview questions")
    else:
        issues.append("Add interview Q&A (lines ending with ?)")

    # 6. Trade-offs / comparisons (0–1 pt)
    has_comparison = any(
        kw in content.lower()
        for kw in ["vs ", "versus", "compared to", "pros", "cons", "trade-off",
                   "advantage", "disadvantage", "when to use", "alternatives"]
    )
    if has_comparison:
        score += 1
        strengths.append("Covers trade-offs and comparisons")
    else:
        issues.append("Add pros/cons or compare with alternatives")

    # 7. Diagrams (0–1 pt bonus)
    has_diagram = "```mermaid" in content
    if has_diagram:
        score += 1
        strengths.append("Has architecture diagrams")

    score = min(score, 10)
    grades = {10: "A+", 9: "A", 8: "A−", 7: "B+", 6: "B", 5: "B−",
              4: "C+", 3: "C", 2: "D", 1: "F", 0: "F"}

    return {
        "score": score,
        "grade": grades.get(score, "F"),
        "issues": issues[:4],
        "strengths": strengths[:3],
        "words": words,
        "code_blocks": code_blocks,
        "sections": h2,
    }


def walk_tree(path: Path) -> list:
    result = []
    try:
        entries = sorted(os.scandir(path), key=lambda e: (not e.is_dir(), e.name.lower()))
        for entry in entries:
            if entry.name in EXCLUDED or entry.name.startswith("."):
                continue
            rel = str(Path(entry.path).relative_to(NOTES_ROOT))
            if entry.is_dir():
                children = walk_tree(Path(entry.path))
                if children:
                    result.append({"type": "dir", "name": entry.name,
                                   "path": rel, "children": children})
            elif Path(entry.name).suffix in VIEW_EXTS:
                status = "code"
                if entry.name.endswith(".md"):
                    try:
                        content = Path(entry.path).read_text("utf-8", errors="ignore")
                        status = note_status(content)
                    except Exception:
                        status = "unknown"
                result.append({"type": "file", "name": entry.name,
                                "path": rel, "status": status})
    except PermissionError:
        pass
    return result


def safe_path(rel: str):
    fp = (NOTES_ROOT / rel).resolve()
    return fp if str(fp).startswith(str(NOTES_ROOT)) else None


@app.route("/")
def index():
    return send_from_directory("static", "index.html")


@app.route("/api/tree")
def api_tree():
    return jsonify(walk_tree(NOTES_ROOT))


@app.route("/api/file", methods=["GET"])
def api_get_file():
    rel = request.args.get("path", "")
    fp = safe_path(rel)
    if fp is None:
        return jsonify({"error": "Forbidden"}), 403
    if not fp.is_file():
        return jsonify({"error": "Not found"}), 404
    content = fp.read_text("utf-8", errors="replace")
    is_md = rel.endswith(".md")
    return jsonify({
        "content": content,
        "path": rel,
        "status": note_status(content) if is_md else "code",
        "quality": score_note(content) if is_md else None,
    })


@app.route("/api/file", methods=["PUT"])
def api_put_file():
    rel = request.args.get("path", "")
    fp = safe_path(rel)
    if fp is None:
        return jsonify({"error": "Forbidden"}), 403
    data = request.get_json() or {}
    content = data.get("content", "")
    fp.write_text(content, "utf-8")
    is_md = rel.endswith(".md")
    return jsonify({
        "success": True,
        "status": note_status(content) if is_md else "code",
        "quality": score_note(content) if is_md else None,
    })


@app.route("/api/search")
def api_search():
    q = request.args.get("q", "").lower().strip()
    if len(q) < 2:
        return jsonify([])
    results = []
    for root, dirs, files in os.walk(NOTES_ROOT):
        dirs[:] = [d for d in dirs if d not in EXCLUDED and not d.startswith(".")]
        for f in files:
            if not f.endswith((".md", ".txt")):
                continue
            fp = Path(root) / f
            try:
                content = fp.read_text("utf-8", errors="ignore")
                if q in content.lower():
                    matches = []
                    for line in content.split("\n"):
                        if q in line.lower() and line.strip():
                            matches.append(line.strip()[:120])
                            if len(matches) >= 3:
                                break
                    results.append({
                        "path": str(fp.relative_to(NOTES_ROOT)),
                        "name": f,
                        "matches": matches,
                    })
                    if len(results) >= 30:
                        return jsonify(results)
            except Exception:
                pass
    return jsonify(results)


@app.route("/api/dashboard")
def api_dashboard():
    """Full dashboard data: stats, categories with quality, gaps, rankings."""
    total = complete = incomplete = empty_count = 0
    categories = []
    all_scored = []
    empty_files = []

    for item in sorted(os.scandir(NOTES_ROOT), key=lambda e: e.name):
        if not item.is_dir() or item.name in EXCLUDED or item.name.startswith("."):
            continue

        ct = cc = ci = ce = 0
        cat_scores = []

        for root, dirs, files in os.walk(item.path):
            dirs[:] = [d for d in dirs if d not in EXCLUDED]
            for f in files:
                if not f.endswith(".md"):
                    continue
                fp = Path(root) / f
                try:
                    content = fp.read_text("utf-8", errors="ignore")
                    s = note_status(content)
                    q = score_note(content)
                    rel = str(fp.relative_to(NOTES_ROOT))
                    ct += 1
                    if s == "complete":
                        cc += 1
                    elif s == "incomplete":
                        ci += 1
                    else:
                        ce += 1
                        empty_files.append({
                            "path": rel, "name": f, "category": item.name,
                        })
                    cat_scores.append(q["score"])
                    all_scored.append({
                        "path": rel, "name": f, "category": item.name,
                        "score": q["score"], "grade": q["grade"],
                        "words": q["words"], "issues": q["issues"][:2],
                        "status": s,
                    })
                except Exception:
                    pass

        if ct > 0:
            avg = round(sum(cat_scores) / len(cat_scores), 1) if cat_scores else 0
            total += ct
            complete += cc
            incomplete += ci
            empty_count += ce
            categories.append({
                "name": item.name, "total": ct,
                "complete": cc, "incomplete": ci, "empty": ce,
                "pct": round(cc / ct * 100),
                "avg_score": avg,
                "grade": _avg_grade(avg),
            })

    # Gap analysis — topics expected but not found
    topic_gaps = []
    for category, topics in EXPECTED_TOPICS.items():
        cat_dir = NOTES_ROOT / category
        for topic in topics:
            found = False
            if cat_dir.exists():
                needle = topic.lower().replace(" ", "")
                for root, dirs, files in os.walk(cat_dir):
                    dirs[:] = [d for d in dirs if d not in EXCLUDED]
                    for f in files:
                        if needle in f.lower().replace(" ", "").replace("-", "").replace("_", ""):
                            found = True
                            break
                        if f.endswith(".md") and not found:
                            try:
                                c = (Path(root) / f).read_text("utf-8", errors="ignore")
                                if topic.lower() in c.lower():
                                    found = True
                            except Exception:
                                pass
                    if found:
                        break
            if not found:
                topic_gaps.append({"category": category, "topic": topic})

    all_sorted = sorted(all_scored, key=lambda x: x["score"])
    return jsonify({
        "stats": {
            "total": total, "complete": complete,
            "incomplete": incomplete, "empty": empty_count,
            "pct": round(complete / total * 100) if total else 0,
            "avg_score": round(sum(x["score"] for x in all_scored) / len(all_scored), 1) if all_scored else 0,
        },
        "categories": sorted(categories, key=lambda c: c["pct"]),
        "empty_files": empty_files[:12],
        "topic_gaps": topic_gaps[:40],
        "worst_notes": all_sorted[:10],
        "best_notes": sorted(all_scored, key=lambda x: -x["score"])[:5],
        "all_notes": all_sorted,
    })


def _avg_grade(avg: float) -> str:
    if avg >= 9: return "A+"
    if avg >= 8: return "A"
    if avg >= 7: return "B+"
    if avg >= 6: return "B"
    if avg >= 5: return "B−"
    if avg >= 4: return "C"
    if avg >= 3: return "D"
    return "F"


@app.errorhandler(Exception)
def handle_exception(e):
    return jsonify({"error": str(e)}), 500

@app.after_request
def add_cors(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, PUT, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    return response

if __name__ == "__main__":
    print(f"\n  Switch Prep UI")
    print(f"  Notes root : {NOTES_ROOT}")
    print(f"  Open in    : http://localhost:5001\n")
    # Listen on 0.0.0.0 so both IPv4 (127.0.0.1) and connections via
    # localhost (which may resolve to ::1 on macOS) can reach the server.
    app.run(port=5001, debug=False, host="0.0.0.0")
