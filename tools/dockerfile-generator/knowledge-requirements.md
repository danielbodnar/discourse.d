To effectively use this Dockerfile generator script, users should have knowledge in the following areas:

1. Docker fundamentals:
   - Understanding of Dockerfile syntax and best practices
   - Docker image layers and caching
   - Docker networking and volume management

2. Bun runtime and shell scripting:
   - Basic Bun syntax and command-line usage
   - Understanding of shell scripting concepts

3. Container orchestration:
   - Familiarity with container registries and image distribution
   - Basic understanding of container lifecycle management

4. Web application deployment:
   - Knowledge of web server configurations (e.g., Nginx)
   - Understanding of application server requirements (e.g., Ruby on Rails)

5. Database systems:
   - Basic understanding of database containers (e.g., PostgreSQL, Redis)

6. Security best practices:
   - Knowledge of least privilege principles
   - Understanding of secure environment variable usage

7. CI/CD concepts:
   - Familiarity with build and test processes in containerized environments

8. Node.js ecosystem:
   - Basic understanding of npm/yarn package management
   - Familiarity with JavaScript/TypeScript

9. Zod and JSON schema:
   - Understanding of data validation and schema definition

10. AI and machine learning concepts:
    - Basic familiarity with AI-assisted code generation
    - Understanding of prompt engineering for AI models

11. Version control systems:
    - Knowledge of Git and GitHub for managing application source code

12. Networking concepts:
    - Understanding of ports, proxies, and network configurations in containerized environments

This knowledge will help users navigate the script's prompts, understand the generated Dockerfile, and make informed decisions about their container configuration.

Please generate a Dockerfile for our Discourse forum application with the following specific requirements:

1. Use the bitnami/discourse:3.2.2 as the base image.
2. Set up the necessary environment variables for our Discourse instance, including SMTP settings.
3. Install additional packages: imagemagick and ffmpeg.
4. Add our custom Discourse plugin from our GitHub repository.
5. Configure content security policy to be disabled and increase the max requests per IP per minute to 120.
6. Ensure that the container runs as a non-root user (UID 1001).
7. Set up a volume for persistent data storage.
8. Expose port 3000 for web traffic.
9. Include a runtime script to start Discourse with proper initialization.
10. Add build steps to install dependencies and precompile assets.
11. Include a test command to run the test suite.
12. Set up lifecycle hooks for database migrations and background job processing.

Please make sure the Dockerfile is optimized for production use, with proper layering to minimize image size and improve build times. Also, include comments in the Dockerfile to explain each significant step for future maintenance.
