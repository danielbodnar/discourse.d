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
