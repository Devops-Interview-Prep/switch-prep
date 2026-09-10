# Docker for Java / Spring Boot Projects

> Java apps compile to a JAR (Maven) or WAR (Gradle). Multi-stage Docker builds separate the compile/package step from the runtime, keeping the final image small. The JDK (~300MB) is only in the build stage; the final image only needs the JRE (~200MB) or a distroless base.

---

## Project Structure — Maven

```
my-spring-app/
├── Dockerfile
├── .dockerignore
├── pom.xml                         # Maven build config + dependencies
├── src/
│   ├── main/
│   │   ├── java/com/example/app/
│   │   │   └── Application.java
│   │   └── resources/
│   │       └── application.properties
│   └── test/
│       └── java/com/example/app/
│           └── ApplicationTests.java
└── target/                         # built output (ignored in Docker)
    └── myapp.jar
```

## Project Structure — Gradle

```
my-spring-app/
├── Dockerfile
├── .dockerignore
├── build.gradle
├── settings.gradle
├── gradlew                         # Gradle wrapper (commit this!)
├── gradle/wrapper/
└── src/
    ├── main/java/com/example/
    └── main/resources/
```

---

## Dockerfile — Maven (Multi-stage)

```dockerfile
# ── Stage 1: Build ──────────────────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy pom.xml first — cache dependency downloads separately from source
COPY pom.xml .
RUN mvn dependency:go-offline -B     # download all deps, -B = batch/non-interactive

# Copy source and build the fat JAR
COPY src/ ./src/
RUN mvn clean package -DskipTests -B  # -DskipTests: skip tests in Docker build

# ── Stage 2: Runtime ────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine AS runtime

WORKDIR /app

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy the fat JAR from builder stage
COPY --from=builder /app/target/*.jar app.jar

USER appuser

EXPOSE 8080

# JVM options: tune memory for container (important!)
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

---

## Dockerfile — Gradle (Multi-stage)

```dockerfile
# ── Stage 1: Build ──────────────────────────────────────────────────────
FROM gradle:8.5-jdk21 AS builder

WORKDIR /app

# Cache Gradle dependencies (copy build files before source)
COPY build.gradle settings.gradle ./
COPY gradle/ ./gradle/
COPY gradlew ./
RUN ./gradlew dependencies --no-daemon    # pre-fetch deps

# Build the application
COPY src/ ./src/
RUN ./gradlew bootJar --no-daemon -x test  # -x test: skip tests

# ── Stage 2: Runtime ────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine AS runtime

WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
```

---

## .dockerignore

```
target/               # Maven build output — rebuilt inside container
build/                # Gradle build output
.git/
*.md
.idea/                # IntelliJ IDE files
*.iml
.mvn/
.gradle/
src/test/             # test sources not needed in production image
```

---

## Build Commands

```bash
# Maven
mvn clean package                  # compile + test + package → target/*.jar
mvn clean package -DskipTests      # skip tests
mvn dependency:go-offline          # pre-download all deps (good for CI caching)

# Gradle
./gradlew bootJar                  # build executable JAR → build/libs/*.jar
./gradlew build -x test            # build, skip tests
./gradlew dependencies             # show dependency tree
```

---

## JVM Container Tuning

```dockerfile
# Before Java 10: JVM didn't know it was inside a container
# It used host machine's RAM, causing OOM kills

# Java 11+: UseContainerSupport is ON by default
# But still important to tune:
ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:InitialRAMPercentage=50.0 \
               -XX:+PrintFlagsFinal"

# MaxRAMPercentage=75.0: use max 75% of container memory limit
# If container limit = 512MB, heap max = ~384MB
```

---

## Comparison: JDK vs JRE vs Distroless

| Base Image | Size | Contains | Use when |
|---|---|---|---|
| `eclipse-temurin:21-jdk` | ~400MB | Full JDK (compiler + tools) | Build stage only |
| `eclipse-temurin:21-jre` | ~250MB | JRE (runtime only) | Most apps |
| `eclipse-temurin:21-jre-alpine` | ~120MB | JRE on Alpine | Smallest, check native lib compat |
| `gcr.io/distroless/java21` | ~200MB | JRE, no shell | Most secure, harder to debug |

---

## Interview Q&A

**Q: Why split Maven/Gradle builds into two Docker stages?**
The build stage needs the full JDK + build tool (~400-700MB). The runtime only needs the JRE (~120-250MB). Multi-stage builds discard the build stage from the final image — only the compiled JAR is copied. This reduces image size by 50-80%, reduces attack surface (no compiler tools in production), and improves pull/push speed in CI/CD. The JAR is self-contained (Spring Boot fat JAR includes all dependencies).

**Q: Why copy `pom.xml` before copying source code?**
Docker layer caching. Dependencies declared in `pom.xml` rarely change compared to source code. By copying `pom.xml` first and running `mvn dependency:go-offline`, those layers are cached and reused unless `pom.xml` changes. Only source code changes in `src/` need to rerun the full `mvn package`. Without this, every source change triggers a full re-download of all dependencies — slow in CI.

**Q: What is `-XX:+UseContainerSupport` and why does it matter?**
Before Java 10, the JVM read `/proc/meminfo` for total system memory and sized its heap accordingly — ignoring Docker's memory limits. A JVM in a 512MB container saw the host's 32GB RAM and allocated a ~8GB heap, causing the container to be OOM-killed by the kernel. `UseContainerSupport` (default from Java 11+) makes the JVM read cgroup memory limits instead. Combined with `MaxRAMPercentage=75.0`, the JVM uses at most 75% of the container's memory limit, leaving 25% for the OS and non-heap memory.
