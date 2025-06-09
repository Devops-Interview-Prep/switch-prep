# Build stage
FROM maven:3.9.4-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml .
COPY src ./src

RUN mvn clean package -DskipTests

#-DskipTests : Skips running the unit tests
#-Dmaven.test.skip=true : Excludes the test task entirely

# Runtime stage
FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]


# With Gradle

# ---------- Stage 1: Build ----------
    FROM gradle:8.6-jdk17 AS builder

    WORKDIR /app
    COPY build.gradle settings.gradle ./
    COPY src ./src
    RUN gradle build -x test

    #-x test : Excludes the test task entirely
    
    
    # ---------- Stage 2: Run ----------
    FROM eclipse-temurin:17-jre-alpine
    
    WORKDIR /app
    COPY --from=builder /app/build/libs/*.jar app.jar
    
    EXPOSE 8080
    CMD ["java", "-jar", "app.jar"]
    
