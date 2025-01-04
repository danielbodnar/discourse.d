# Prompt Template: Dockerfile Generator for Discourse Forum Application


## Prompt

You are tasked with creating a Bun shell script that will generate a Dockerfile or OCI rootfs directory based on user input and configuration values. This script should be highly configurable and generic, capable of handling various aspects of container configuration.

First, analyze the following existing Dockerfile or container information:

<existing_dockerfile_or_container>
{{EXISTING_DOCKERFILE_OR_CONTAINER}}
</existing_dockerfile_or_container>

Next, review the configuration values specified by the user:

<user_config>
{{USER_CONFIG}}
</user_config>


Third, review the tech stack requirements:
<teckstack>
{{TECHSTACK}}
</techstack>

Fourth, familiarize yourself with the following knowledge prerequisites:

<knowledge_requirements>
{{KNOWLEDGE_REQUIREMENTS}}
</knowledge_requirements>


Finally, review the user's custom instructions:

<instructions>
{{INSTRUCTIONS}}
</instructions>


Your task is to create a Bun shell script that will prompt the user for variables and configuration values and use those to generate a Dockerfile or OCI rootfs directory.

The bun shell guide is here : https://bun.sh/docs/runtime/shell

The following steps will need to be configured:

- container registry
- base image
- build args
- environment variables
- proxy and no_proxy values
- ca-certificates
- os packages (intelligently determine package manager)
- app sources and repos
- custom configurations
- layered overlays and
- build steps
- test commands
- lifecycle hooks
- user and groups
- volumes and mounts
- exposed ports
- runtime scripts

Everything should be configurable and generic.

Use bun as the node js runtime, package manager, and bash shell environment.
Use citty, consola, magicast, and c12 to prompt the user for configuration values, then save them to "./docker.config.ts" with c12 and magicast. Use Zod and zod-to-json-schema to create a zod-object per configuration section above. Use Consola to prompt the user for values, and those Zod schemas to determine defaults, prompt types (multi select, string, int, etc), and zod's ".describe()" key to determine the text to display to the user while promoting them for a configuration value.

The very this script should do is prompt the user for a docker image or a docker container or a Dockerfile and then attempt to extract and infer as many of these values from the container image, Dockerfile, or docker container.

This CLI should also provide an option for using ollama.js,  llamaindexts, or '@anthropic-ai/sdk' and 'claude3-5-sonnet-latest' to generate the actual Dockerfile by using the Zod schemas as a tool calling input schema.

Use archlinux as a default container example.


Now, follow these steps to create the Bun shell script:

1. Set up the Bun shell script environment:
   - Create a new file named `dockerfile-generator.ts`
   - At the top of the file, add the shebang line: `#!/usr/bin/env bun`

2. Import and configure the necessary libraries:
   ```typescript
   import { $, file } from 'bun';
   import { consola } from 'consola';
   import { z } from 'zod';
   import { zodToJsonSchema } from 'zod-to-json-schema';
   import { defineConfig } from 'c12';
   import { createMagicGetter, createMagicSetter } from 'magicast';
   import { Ollama } from 'ollama';
   import { Document } from 'llamaindex';
   import { AnthropicClient } from '@anthropic-ai/sdk';
   ```

3. Create Zod schemas for each configuration section:
   ```typescript
   const ContainerRegistrySchema = z.object({
     // Define schema for container registry
   }).describe('Container registry configuration');

   const BaseImageSchema = z.object({
     // Define schema for base image
   }).describe('Base image configuration');

   // Create similar schemas for all other configuration sections
   ```

4. Extract and infer values from the existing Dockerfile or container:
   - Implement a function to parse the existing_dockerfile_or_container input
   - Extract relevant information for each configuration section
   - Store the extracted values in an object for later use

5. Prompt the user for configuration values using Consola and Zod schemas:
   ```typescript
   async function promptForConfig(schema: z.ZodObject<any>, existingValues: any) {
     const result = {};
     for (const [key, value] of Object.entries(schema.shape)) {
       const defaultValue = existingValues[key] || value._def.defaultValue();
       const description = value.description;
       result[key] = await consola.prompt(`${description} (default: ${defaultValue})`);
     }
     return result;
   }

   const containerRegistryConfig = await promptForConfig(ContainerRegistrySchema, extractedValues.containerRegistry);
   const baseImageConfig = await promptForConfig(BaseImageSchema, extractedValues.baseImage);
   // Prompt for all other configuration sections
   ```

6. Save the configuration to docker.config.ts using c12 and magicast:
   ```typescript
   const config = {
     containerRegistry: containerRegistryConfig,
     baseImage: baseImageConfig,
     // Include all other configuration sections
   };

   await defineConfig({
     name: 'docker',
     defaults: config,
     layers: [
       {
         config: createMagicSetter(config),
         configFile: file('./docker.config.ts'),
       },
     ],
   });
   ```

7. Generate the Dockerfile using the configuration values:
   ```typescript
   function generateDockerfile(config: any) {
     let dockerfile = '';
     // Use the config object to generate each section of the Dockerfile
     // Example:
     dockerfile += `FROM ${config.baseImage.name}:${config.baseImage.tag}\n`;
     // Add all other Dockerfile instructions based on the config
     return dockerfile;
   }

   const generatedDockerfile = generateDockerfile(config);
   await Bun.write('Dockerfile', generatedDockerfile);
   ```

8. Implement AI-assisted Dockerfile generation option:
   ```typescript
   async function generateDockerfileWithAI(config: any) {
     const prompt = `Generate a Dockerfile based on the following configuration:\n${JSON.stringify(config, null, 2)}`;

     // Choose one of the following AI options:

     // Option 1: Ollama
     const ollama = new Ollama();
     const response = await ollama.generate({
       model: 'codellama',
       prompt: prompt,
     });

     // Option 2: LlamaIndex
     const document = new Document({ text: prompt });
     const response = await document.retrieve();

     // Option 3: Anthropic Claude
     const client = new AnthropicClient({ apiKey: process.env.ANTHROPIC_API_KEY });
     const response = await client.complete({
       model: 'claude-3-sonnet-20241022',
       prompt: prompt,
       max_tokens_to_sample: 8192,
     });

     return response.text;
   }

   // Prompt user to choose between manual or AI-assisted generation
   const useAI = await consola.confirm('Do you want to use AI to generate the Dockerfile?');
   const finalDockerfile = useAI ? await generateDockerfileWithAI(config) : generateDockerfile(config);
   await Bun.write('Dockerfile', finalDockerfile);
   ```

9. Conclusion and output:
   Print a success message and the location of the generated Dockerfile:
   ```typescript
   consola.success('Dockerfile generated successfully!');
   consola.info(`Dockerfile location: ${process.cwd()}/Dockerfile`);
   ```

Ensure that your script handles errors gracefully and provides clear feedback to the user throughout the process. The final output should be a generated Dockerfile based on the user's configuration choices, with an option to use AI assistance for generation.



--------------

## Variables

### Generation Logic

```markdown
1. The prompt template aims to create a Bun shell script that generates a Dockerfile or OCI rootfs directory based on user input and configuration values. The goal is to provide a highly configurable and generic tool for container configuration, with options for AI-assisted generation.


2. Variable considerations:

EXISTING_DOCKERFILE_OR_CONTAINER: This would likely be provided by the end user, either as a path to an existing Dockerfile or as a Docker image/container name. It should be a realistic Dockerfile or container specification. Use bitnami/discourse:v3.2.2 or discourse/discourse_dev, or archlinux:latest to generate these if not already specified.

USER_CONFIG: This would be input by the end user, likely through a series of prompts or a configuration file. It should include various container configuration settings in a structured format.

TECHSTACK: This would be specified by the end user, listing the technologies and frameworks used in their application. It should be a concise list of relevant technologies.

Always include the following requirements:
- [bun](https://github.com/bun-sh/bun)
- [unjs/citty](https://github.com/unjs/citty)
- [unjs/consola](https://github.com/unjs/consola)
- [unjs/c12](https://github.com/unjs/c12)
- [unjs/magicast](https://github.com/unjs/magicast)
- [unjs/defu](https://github.com/unjs/defu)
- llamaindexts
- ollama.js


KNOWLEDGE_REQUIREMENTS: This would be pre-defined by the prompt creator, listing the necessary knowledge areas for understanding and using the script. It should cover Docker, Bun, and related technologies.

INSTRUCTIONS: This would be provided by the end user, giving any specific instructions or requirements for their container setup. It should be written in a clear, instructional tone.
```


### EXISTING_DOCKERFILE_OR_CONTAINER

```Dockerfile
# Use an official Discourse base image
FROM bitnami/discourse:3.2.2

# Set environment variables
ENV DISCOURSE_HOSTNAME=mydiscourse.example.com
ENV DISCOURSE_DEVELOPER_EMAILS=admin@example.com
ENV DISCOURSE_SMTP_ADDRESS=smtp.example.com
ENV DISCOURSE_SMTP_PORT=587
ENV DISCOURSE_SMTP_USER_NAME=smtpuser
ENV DISCOURSE_SMTP_PASSWORD=smtppassword

# Install additional packages
USER root
RUN apt-get update && apt-get install -y \
    imagemagick \
    ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Switch back to non-root user
USER 1001

# Expose ports
EXPOSE 3000

# Set the default command to run Discourse
CMD ["./app-entrypoint.sh"]
```

### USER_CONFIG
```json
{
  "containerRegistry": {
    "url": "registry.example.com",
    "username": "myuser",
    "password": "mypassword"
  },
  "baseImage": {
    "name": "bitnami/discourse",
    "tag": "3.2.2"
  },
  "buildArgs": {
    "DISCOURSE_VERSION": "3.2.2"
  },
  "environmentVariables": {
    "DISCOURSE_HOSTNAME": "mydiscourse.example.com",
    "DISCOURSE_DEVELOPER_EMAILS": "admin@example.com",
    "DISCOURSE_SMTP_ADDRESS": "smtp.example.com",
    "DISCOURSE_SMTP_PORT": "587",
    "DISCOURSE_SMTP_USER_NAME": "smtpuser",
    "DISCOURSE_SMTP_PASSWORD": "smtppassword"
  },
  "proxySettings": {
    "httpProxy": "http://proxy.example.com:8080",
    "httpsProxy": "http://proxy.example.com:8080",
    "noProxy": "localhost,127.0.0.1"
  },
  "caCertificates": [
    "/path/to/custom-ca.crt"
  ],
  "osPackages": [
    "imagemagick",
    "ffmpeg"
  ],
  "appSources": {
    "repoUrl": "https://github.com/myuser/discourse-custom-plugin.git",
    "branch": "main"
  },
  "customConfigurations": {
    "discourse.conf": "content_security_policy = false\nmax_reqs_per_ip_per_minute = 120"
  },
  "buildSteps": [
    "bundle install",
    "yarn install",
    "rake assets:precompile"
  ],
  "testCommands": [
    "bundle exec rspec"
  ],
  "lifecycleHooks": {
    "preStart": "bundle exec rake db:migrate",
    "postStart": "bundle exec rake jobs:work"
  },
  "userAndGroups": {
    "user": "discourse",
    "uid": 1001,
    "group": "discourse",
    "gid": 1001
  },
  "volumesAndMounts": [
    {
      "name": "discourse-data",
      "mountPath": "/bitnami/discourse"
    }
  ],
  "exposedPorts": [3000],
  "runtimeScripts": [
    {
      "name": "start-discourse",
      "content": "#!/bin/bash\n./app-entrypoint.sh"
    }
  ]
}
```


### TECHSTACK
```markdown

- [bun](https://github.com/unjs/consola)
- [unjs/citty](https://github.com/unjs/citty)
- [unjs/consola](https://github.com/unjs/consola)
- [unjs/c12](https://github.com/unjs/c12)
- [unjs/magicast](https://github.com/unjs/magicast)
- llamaindexts
- ollama.js

```


### KNOWLEDGE_REQUIREMENTS
```markdown

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


```



### INSTRUCTIONS
```markdown

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

```
