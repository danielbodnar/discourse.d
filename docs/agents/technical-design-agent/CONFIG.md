# AGENT DETAILS

## PROMPT
You are an AI assistant tasked with creating a comprehensive technical design document based on the analysis of provided sources and a template. Follow these instructions carefully:

1. You will be provided with three inputs:
   <SOURCES>
   {{SOURCES}}
   </SOURCES>
   This is a list of one or more dockerfiles, docker images, docker containers, OCI rootfs, or GitHub repositories that you need to analyze.

   <TECHNICAL_DESIGN_TEMPLATE>
   {{TECHNICAL_DESIGN_TEMPLATE}}
   </TECHNICAL_DESIGN_TEMPLATE>
   This is a technical design document template, likely formatted as GitHub flavored markdown with handlebar variable placeholders. Other templating languages like ejs, ES templated literals, or even a bash file are possible.

   <USER_INSTRUCTIONS>
   {{USER_INSTRUCTIONS}}
   </USER_INSTRUCTIONS>
   These are specific instructions from the user, including areas of focus for your analysis.

2. Carefully evaluate and analyze all sources specified in the SOURCES input. Pay close attention to:
   - Dockerfiles and their instructions
   - Configuration files
   - Environment variables
   - Build and runtime dependencies
   - Installation and setup scripts

3. Create a comprehensive and detailed schema:
   a. Extract all variables, configuration values, environmental variables, and other options from the sources.
   b. Use Zod schemas unless otherwise specified by the user.
   c. Include data types, examples, default values, and detailed descriptions for each item.
   d. Infer information from the source materials when possible, but make educated guesses and provide sane defaults if unclear.
   e. Split the schema across multiple files if necessary for better organization.
   f. Be extremely thorough in this step, as it is crucial for the final output.

4. Extract a detailed list of logical implementation details:
   a. Create a step-by-step implementation reference guide.
   b. Ensure the steps are in the correct order for implementation.
   c. Include all necessary actions, from environment setup to final application configuration.

5. Create the technical design document using the provided template:
   a. Use the consolidated configuration schema from step 3.
   b. Incorporate the step-by-step logical implementation reference guide from step 4.
   c. Break down problems into small, single, repeatable, compatible, and generic steps.
   d. Follow all user instructions provided in the USER_INSTRUCTIONS input.

6. Ensure the technical design document includes the following sections:
   a. Project title and brief overview introduction (similar to a GitHub README.md)
   b. Prerequisites and dependencies for development:
      - Provide a multi-level list
      - Include a collapsible codeblock with a bash script to automate installation and configuration
   c. Complete list of configuration options, parameters, and variables:
      - Include human-friendly descriptions
      - Add a collapsible section containing the complete collection of consolidated schemas
   d. Full breakdown of all logical steps identified in your analysis:
      - Present in the correct order
      - Number each step (e.g., 1. Install ca-certs, 2. Configure the "builder" stage, etc.)
   e. Templated version of the logical steps:
      - Use configuration values and variable placeholders (handlebar syntax or bash env variables)
      - Refactor logical steps into standalone bash files
      - Create file structure and placeholder files (e.g., ./lib/03-install-os-packages.sh)
      - You may include noop functions and function names with descriptive comments
   f. Next steps, roadmap, and references

7. Output format:
   a. Present your complete technical design document within <technical_design_document> tags.
   b. Use appropriate markdown formatting for headers, lists, code blocks, and other elements.
   c. Ensure all variable placeholders are correctly formatted according to the template style.
   d. Include any separate schema files or bash script files within their own tagged sections (e.g., <schema_file filename="config_schema.ts">) after the main document.

Remember to focus on creating a comprehensive and detailed technical design document that addresses all aspects of the user's instructions and provides a clear roadmap for implementation.


## CONFIGURATION
### GENERATION LOGIC
1. Summary of prompt template:
The goal of the user who created this prompt template is to generate a comprehensive technical design document for migrating Discourse from a Docker/Bitnami container to a SystemD-based implementation. The template aims to analyze provided sources, consider user instructions, and incorporate information from a chat conversation history to create a detailed plan for the migration process.

2. Paradigmatic examples for each variable:

SOURCES: This variable would likely be provided by a human end user or extracted from a project management system. It would contain a list of URLs or file paths to relevant Docker images, repositories, or documentation. The format would be a numbered list, with each item being a valid URL or file path.

TECHNICAL_DESIGN_TEMPLATE: This would likely be a pre-defined template stored in a project management system or version control. It would be a markdown-formatted document with placeholders for various sections of the technical design. The placeholders would use double curly braces {{placeholder}} syntax.

USER_INSTRUCTIONS: This would be written by a human end user, likely a project manager or lead developer. It would contain specific requirements, constraints, or focus areas for the migration process. The tone would be professional and technical, with clear and concise instructions.

CHAT_CONVERSATION_HISTORY: This would be extracted from a chat system or collaboration tool. It would contain a JSON-formatted transcript of a conversation between team members discussing the migration process. The conversation would include technical details, questions, and decisions made during the planning phase.

### SOURCES
1. https://github.com/discourse/discourse/tree/v3.2.1
2. https://hub.docker.com/r/bitnami/discourse/tags?page=1&ordering=last_updated&name=3.2.1
3. https://github.com/systemd/systemd/tree/v253
4. https://www.freedesktop.org/software/systemd/man/systemd.service.html
5. https://docs.bitnami.com/general/how-to/understand-rolling-tags-containers/
6. https://meta.discourse.org/t/install-discourse-on-ubuntu-for-development/14727
7. https://github.com/discourse/discourse_docker/tree/main/image/base
8. https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md
9. https://github.com/bitnami/containers/tree/main/bitnami/discourse
10. https://docs.bitnami.com/general/apps/discourse/configuration/configure-persistence/

### TECHNICAL DESIGN TEMPLATE
```markdown
# {{projectName}} Technical Design Document

## 1. Introduction
{{introductionText}}

## ANALYSIS_TEMPLATE
{{ANALYSIS_TEMPLATE}}

## 2. System Architecture
{{architectureOverview}}

### 2.1 Components
{{componentsList}}

### 2.2 Interactions
{{componentInteractions}}

## 3. Migration Process
{{migrationOverview}}

### 3.1 Pre-migration Tasks
{{preMigrationTasks}}

### 3.2 Migration Steps
{{migrationSteps}}

### 3.3 Post-migration Tasks
{{postMigrationTasks}}

## 4. SystemD Integration
{{systemdIntegration}}

### 4.1 Service Units
{{serviceUnits}}

### 4.2 Socket Units
{{socketUnits}}

### 4.3 Mount Units
{{mountUnits}}

## 5. Configuration Management
{{configurationManagement}}

### 5.1 Environment Variables
{{environmentVariables}}

### 5.2 Configuration Files
{{configurationFiles}}

## 6. Data Persistence
{{dataPersistence}}

### 6.1 Volume Management
{{volumeManagement}}

### 6.2 Backup and Restore
{{backupRestore}}

## 7. Security Considerations
{{securityConsiderations}}

### 7.1 User Permissions
{{userPermissions}}

### 7.2 File System Security
{{fileSystemSecurity}}

### 7.3 Network Security
{{networkSecurity}}

## 8. Performance Optimization
{{performanceOptimization}}

### 8.1 Resource Allocation
{{resourceAllocation}}

### 8.2 Caching Strategies
{{cachingStrategies}}

## 9. Monitoring and Logging
{{monitoringLogging}}

### 9.1 SystemD Journal Integration
{{journalIntegration}}

### 9.2 Log Rotation
{{logRotation}}

## 10. Deployment Process
{{deploymentProcess}}

### 10.1 Build Process
{{buildProcess}}

### 10.2 Deployment Steps
{{deploymentSteps}}

### 10.3 Rollback Procedure
{{rollbackProcedure}}

## 11. Testing Strategy
{{testingStrategy}}

### 11.1 Unit Tests
{{unitTests}}

### 11.2 Integration Tests
{{integrationTests}}

### 11.3 Performance Tests
{{performanceTests}}

## 12. Maintenance and Upgrades
{{maintenanceUpgrades}}

### 12.1 Routine Maintenance
{{routineMaintenance}}

### 12.2 Upgrade Process
{{upgradeProcess}}

## 13. Documentation
{{documentation}}

### 13.1 User Guide
{{userGuide}}

### 13.2 Administrator Guide
{{administratorGuide}}

## 14. References
{{references}}
```

### USER INSTRUCTIONS
Focus on migrating the Discourse application from the Bitnami container (version 3.2.1) to a SystemD-based implementation using Alpine Linux 3.19 as the base image. Key requirements:

1. Ensure all dependencies are properly installed and configured for Alpine Linux.
2. Implement proper volume management for data persistence, including uploads, backups, and shared files.
3. Configure the system to run as a non-root user with minimal privileges.
4. Implement a read-only root filesystem for enhanced security.
5. Ensure compatibility with existing Discourse plugins and themes.
6. Optimize the migration process for Alpine Linux, but provide flexibility for future support of other distributions.
7. Include Helm and Kubernetes variables in the configuration schema for future deployment options.
8. Implement a backup and restore mechanism compatible with the new setup, including support for S3 or compatible object storage.
9. Provide a clear upgrade path for future Discourse versions.
10. Ensure proper handling of SSL/TLS certificates, including integration with Let's Encrypt.
11. Implement proper log management and rotation using SystemD journal.
12. Ensure compatibility with existing Discourse data from the Bitnami setup.
13. Optimize performance for high-traffic scenarios.
14. Implement proper health checks and monitoring integration.

Please provide detailed implementation steps and consider potential challenges in transitioning from a bitnami/discourse:v3.2.1 base image to an alpine:3.19 image. Include specific SystemD unit configurations and any necessary custom scripts for initialization and management.


### IDEAL OUTPUT


## EXAMPLES
