# Stage 1: Build the application using a full JDK
# Use a specific version tag for better stability
FROM openjdk:21-jdk-slim as builder

# Set environment variable for the JAR file name based on pom.xml artifactId and version
# This ensures consistency for the final run stage
# You can replace 'CarCare' with your project's artifactId if different
ENV ARTIFACT_NAME CarCare-0.0.1-SNAPSHOT.jar 

# Set the working directory
WORKDIR /app

# Copy Maven wrapper files and pom.xml
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Grant execute permission to the Maven wrapper script (Good practice)
RUN chmod +x mvnw

# Download dependencies to leverage Docker cache
# This step is only re-run when pom.xml changes
RUN ./mvnw dependency:go-offline

# Copy the rest of the application source code
COPY src ./src

# Package the application, skipping tests
RUN ./mvnw clean package -DskipTests

# Stage 2: Create the final, lightweight image with only the JRE
# JRE is sufficient for running the compiled application
FROM openjdk:21-jre-slim

# Set the working directory for the runtime container
WORKDIR /app

# Copy the environment variable from the previous stage
ARG ARTIFACT_NAME

# Copy the built JAR from the builder stage and rename it to 'app.jar'
# Using *.jar simplifies the copy step and avoids hardcoding the version
COPY --from=builder /app/target/*.jar app.jar

# Expose the default Spring Boot port
EXPOSE 8080

# Run the application
# Use the official port environment variable for Spring Boot
# Note: Spring Boot default is 8080, but using the variable is safer.
CMD ["java", "-jar", "/app/app.jar"]