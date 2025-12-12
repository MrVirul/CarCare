# Stage 1: Build the application using a full JDK
FROM openjdk:21-jdk-slim as builder

# Set the working directory
WORKDIR /app

# Copy Maven wrapper files
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Download dependencies to leverage Docker cache
# This step is only re-run when pom.xml changes
RUN ./mvnw dependency:go-offline

# Copy the rest of the application source code
COPY src ./src

# Package the application, skipping tests
RUN ./mvnw clean package -DskipTests

# Stage 2: Create the final, lightweight image with only the JRE
FROM openjdk:21-jre-slim

WORKDIR /app

# Define a build argument for the JAR file
ARG JAR_FILE=target/CarCare-0.0.1-SNAPSHOT.jar

# Copy the JAR from the builder stage
COPY --from=builder /app/${JAR_FILE} app.jar

# Expose the default Spring Boot port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java","-jar","/app/app.jar"]
