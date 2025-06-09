```
my-spring-app/
├── pom.xml
├── src/
│   └── main/
│       └── java/
│       └── resources/
└── Dockerfile
```

📁 1. Java with Maven (e.g., Spring Boot)

```
myapp/
├── Dockerfile
├── pom.xml
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/myapp/
│   │   │       └── Application.java
│   │   └── resources/
│   │       └── application.properties
│   └── test/
│       └── java/
│           └── com/example/myapp/
│               └── ApplicationTests.java
```

`mvn clean package`

- Produces a target/myapp.jar (fat jar) if Spring Boot is used.


📁 2. Java with Gradle

```
myapp/
├── Dockerfile
├── build.gradle
├── settings.gradle
├── src/
│   ├── main/java/com/example/
│   └── main/resources/
```

`./gradlew build`

- Outputs .jar to build/libs/myapp.jar
