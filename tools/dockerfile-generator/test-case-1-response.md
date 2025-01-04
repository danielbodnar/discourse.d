# Bun Shell Script for Dockerfile Generation

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

Now please create a comprehensive Bun shell script for Dockerfile generation. Here's an incomplete example, broke down into multiple files:


## Examples

### Example Dockerfile:

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

## Example Config
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


## TechStack (package.json)
```json
// package.json
{
  "name": "dockerfile-generator",
  "version": "1.0.0",
  "module": "index.ts",
  "type": "module",
  "devDependencies": {
    "bun-types": "latest"
  },
  "dependencies": {
    "@anthropic-ai/sdk": "^0.18.0",
    "c12": "^1.10.0",
    "citty": "^0.1.5",
    "consola": "^3.2.3",
    "defu": "^6.1.4",
    "llamaindex": "^0.1.7",
    "magicast": "^0.3.3",
    "ollama": "^0.4.9",
    "zod": "^3.22.4",
    "zod-to-json-schema": "^3.22.3"
  }
}
```

## Schemas

```typescript
// src/schemas
import { z } from 'zod';

export const ContainerRegistrySchema = z.object({
  url: z.string().url().describe('Container registry URL'),
  username: z.string().describe('Registry username'),
  password: z.string().describe('Registry password')
}).describe('Container registry configuration');

export const BaseImageSchema = z.object({
  name: z.string().default('archlinux').describe('Base image name'),
  tag: z.string().default('latest').describe('Base image tag')
}).describe('Base image configuration');

export const BuildArgsSchema = z.record(z.string()).describe('Build arguments');

export const EnvironmentVariablesSchema = z.record(z.string()).describe('Environment variables');

export const ProxySettingsSchema = z.object({
  httpProxy: z.string().optional().describe('HTTP proxy URL'),
  httpsProxy: z.string().optional().describe('HTTPS proxy URL'),
  noProxy: z.string().optional().describe('No proxy list')
}).describe('Proxy settings');

export const CaCertificatesSchema = z.array(z.string()).describe('CA certificates');

export const OSPackagesSchema = z.array(z.string()).describe('OS packages to install');

export const AppSourcesSchema = z.object({
  repoUrl: z.string().url().optional().describe('Repository URL'),
  branch: z.string().default('main').describe('Repository branch')
}).describe('Application source configuration');

export const CustomConfigurationsSchema = z.record(z.string()).describe('Custom configurations');

export const BuildStepsSchema = z.array(z.string()).describe('Build steps');

export const TestCommandsSchema = z.array(z.string()).describe('Test commands');

export const LifecycleHooksSchema = z.object({
  preStart: z.string().optional().describe('Pre-start hook'),
  postStart: z.string().optional().describe('Post-start hook')
}).describe('Lifecycle hooks');

export const UserAndGroupsSchema = z.object({
  user: z.string().describe('Container user'),
  uid: z.number().describe('User ID'),
  group: z.string().describe('Container group'),
  gid: z.number().describe('Group ID')
}).describe('User and groups configuration');

export const VolumesAndMountsSchema = z.array(
  z.object({
    name: z.string().describe('Volume name'),
    mountPath: z.string().describe('Mount path')
  })
).describe('Volumes and mounts configuration');

export const ExposedPortsSchema = z.array(z.number()).describe('Exposed ports');

export const RuntimeScriptsSchema = z.array(
  z.object({
    name: z.string().describe('Script name'),
    content: z.string().describe('Script content')
  })
).describe('Runtime scripts');

export const DockerConfigSchema = z.object({
  containerRegistry: ContainerRegistrySchema,
  baseImage: BaseImageSchema,
  buildArgs: BuildArgsSchema,
  environmentVariables: EnvironmentVariablesSchema,
  proxySettings: ProxySettingsSchema,
  caCertificates: CaCertificatesSchema,
  osPackages: OSPackagesSchema,
  appSources: AppSourcesSchema,
  customConfigurations: CustomConfigurationsSchema,
  buildSteps: BuildStepsSchema,
  testCommands: TestCommandsSchema,
  lifecycleHooks: LifecycleHooksSchema,
  userAndGroups: UserAndGroupsSchema,
  volumesAndMounts: VolumesAndMountsSchema,
  exposedPorts: ExposedPortsSchema,
  runtimeScripts: RuntimeScriptsSchema
}).describe('Complete Docker configuration');
```

### Utils

```typescript
// src/utils/docker-parser.ts
import { $ } from 'bun';

export async function parseDockerfile(path: string) {
  try {
    const content = await Bun.file(path).text();
    // Parse Dockerfile content and extract configuration
    // This is a simplified example
    return {
      baseImage: {
        name: content.match(/FROM\s+(\w+)/)?.[1] || 'archlinux',
        tag: content.match(/FROM\s+\w+:(\w+)/)?.[1] || 'latest'
      },
      // Add more parsing logic for other sections
    };
  } catch (error) {
    console.error('Error parsing Dockerfile:', error);
    return null;
  }
}

export async function inspectContainer(containerName: string) {
  try {
    const { stdout } = await $`docker inspect ${containerName}`;
    const inspection = JSON.parse(stdout);
    // Extract configuration from container inspection
    return {
      // Convert inspection data to config format
    };
  } catch (error) {
    console.error('Error inspecting container:', error);
    return null;
  }
}
```


### Generators
```typescript
// src/generators/dockerfile.ts
import type { DockerConfig } from '../types';

export function generateDockerfile(config: DockerConfig): string {
  const parts: string[] = [];

  // Base image
  parts.push(`FROM ${config.baseImage.name}:${config.baseImage.tag}`);

  // Environment variables
  Object.entries(config.environmentVariables).forEach(([key, value]) => {
    parts.push(`ENV ${key}=${value}`);
  });

  // OS packages
  if (config.osPackages.length > 0) {
    // Detect package manager based on base image
    const packageManager = getPackageManager(config.baseImage.name);
    parts.push(generatePackageInstallation(packageManager, config.osPackages));
  }

  // User and groups
  parts.push(`
RUN groupadd -g ${config.userAndGroups.gid} ${config.userAndGroups.group} && \
    useradd -u ${config.userAndGroups.uid} -g ${config.userAndGroups.group} ${config.userAndGroups.user}
  `);

  // Add more sections based on config

  return parts.join('\n\n');
}

function getPackageManager(baseImage: string): string {
  const packageManagers = {
    'archlinux': 'pacman -Sy',
    'ubuntu': 'apt-get update && apt-get install -y',
    'alpine': 'apk add --no-cache',
    // Add more package managers
  };
  return packageManagers[baseImage] || 'pacman -Sy';
}

function generatePackageInstallation(packageManager: string, packages: string[]): string {
  return `RUN ${packageManager} ${packages.join(' ')}`;
}
```



```typescript
// dockerfile-generator.ts
#!/usr/bin/env bun

import { consola } from 'consola';
import { defineCommand } from 'citty';
import { defineConfig } from 'c12';
import { DockerConfigSchema } from './src/schemas';
import { parseDockerfile, inspectContainer } from './src/utils/docker-parser';
import { generateDockerfile } from './src/generators/dockerfile';
import { Ollama } from 'ollama';
import { AnthropicClient } from '@anthropic-ai/sdk';

const main = defineCommand({
  meta: {
    name: 'dockerfile-generator',
    description: 'Generate Dockerfile from configuration',
  },
  async run({ args }) {
    try {
      // Step 1: Get existing configuration
      const existingConfig = await getExistingConfig();

      // Step 2: Prompt for configuration values
      const config = await promptForConfig(existingConfig);

      // Step 3: Save configuration
      await saveConfig(config);

      // Step 4: Generate Dockerfile
      const useAI = await consola.confirm('Use AI to generate Dockerfile?');
      const dockerfile = useAI
        ? await generateDockerfileWithAI(config)
        : generateDockerfile(config);

      // Step 5: Save Dockerfile
      await Bun.write('Dockerfile', dockerfile);
      consola.success('Dockerfile generated successfully!');

    } catch (error) {
      consola.error('Error generating Dockerfile:', error);
      process.exit(1);
    }
  }
});

async function getExistingConfig() {
  const source = await consola.prompt(
    'Enter path to existing Dockerfile or container name (optional):'
  );

  if (!source) return null;

  if (source.includes('Dockerfile')) {
    return await parseDockerfile(source);
  } else {
    return await inspectContainer(source);
  }
}

async function promptForConfig(existingConfig: any) {
  // Implementation of configuration prompting
  // Use consola to prompt for each configuration section
  // Validate input using Zod schemas
}

async function saveConfig(config: any) {
  await defineConfig({
    name: 'docker',
    defaults: config,
    layers: [{
      config,
      configFile: './docker.config.ts'
    }]
  });
}

async function generateDockerfileWithAI(config: any) {
  const aiProvider = await consola.select('Choose AI provider:', [
    'Ollama',
    'Claude'
  ]);

  const prompt = `Generate a Dockerfile with these requirements:
    ${JSON.stringify(config, null, 2)}`;

  switch (aiProvider) {
    case 'Ollama':
      const ollama = new Ollama();
      const response = await ollama.generate({
        model: 'codellama',
        prompt
      });
      return response.text;

    case 'Claude':
      const claude = new AnthropicClient({
        apiKey: process.env.ANTHROPIC_API_KEY
      });
      const completion = await claude.messages.create({
        model: 'claude-3-sonnet-20240229',
        max_tokens: 4096,
        messages: [{
          role: 'user',
          content: prompt
        }]
      });
      return completion.content[0].text;
  }
}

// Run the command
main.parse(process.argv);
```



1. First, create `src/schemas/docker.config.ts`:

```typescript
import { z } from 'zod';

export const ContainerRegistrySchema = z.object({
  url: z.string().url().describe('Container registry URL'),
  username: z.string().optional().describe('Registry username'),
  password: z.string().optional().describe('Registry password')
}).describe('Container registry configuration');

export const BaseImageSchema = z.object({
  name: z.string().default('archlinux').describe('Base image name'),
  tag: z.string().default('latest').describe('Base image tag')
}).describe('Base image configuration');

export const ProxySettingsSchema = z.object({
  httpProxy: z.string().optional().describe('HTTP proxy URL'),
  httpsProxy: z.string().optional().describe('HTTPS proxy URL'),
  noProxy: z.string().optional().describe('No proxy list')
}).describe('Proxy settings');

export const PackageManagerSchema = z.enum(['pacman', 'apt', 'apk', 'yum', 'dnf'])
  .describe('Package manager');

export const OSPackagesSchema = z.array(
  z.string()
).describe('OS packages to install');

// Add more schemas for other sections...

export const DockerConfigSchema = z.object({
  containerRegistry: ContainerRegistrySchema,
  baseImage: BaseImageSchema,
  proxySettings: ProxySettingsSchema,
  packageManager: PackageManagerSchema,
  osPackages: OSPackagesSchema,
  // Include other schemas...
}).describe('Complete Docker configuration');

export type DockerConfig = z.infer<typeof DockerConfigSchema>;
```

2. Create `src/utils/docker-parser.ts`:

```typescript
import { $ } from 'bun';
import type { DockerConfig } from '../schemas/docker.config';

export async function parseExistingDocker(source: string): Promise<Partial<DockerConfig>> {
  if (source.includes('Dockerfile')) {
    return parseDockerfile(source);
  } else {
    return parseContainer(source);
  }
}

async function parseDockerfile(path: string): Promise<Partial<DockerConfig>> {
  const content = await Bun.file(path).text();

  const baseImage = content.match(/FROM\s+([^\s]+)/)?.[1]?.split(':') || [];
  const packages = content.match(/RUN\s+(pacman|apt-get|apk)\s+install\s+([^\n]+)/)?.[2]?.split(/\s+/) || [];

  return {
    baseImage: {
      name: baseImage[0] || 'archlinux',
      tag: baseImage[1] || 'latest'
    },
    osPackages: packages
  };
}

async function parseContainer(name: string): Promise<Partial<DockerConfig>> {
  try {
    const { stdout } = await $`docker inspect ${name}`;
    const info = JSON.parse(stdout)[0];

    return {
      baseImage: {
        name: info.Config.Image.split(':')[0],
        tag: info.Config.Image.split(':')[1] || 'latest'
      },
      // Extract more configuration...
    };
  } catch (error) {
    console.error('Error inspecting container:', error);
    return {};
  }
}
```


#### src/generators/dockerfile-generator.ts

```typescript
// src/generators/dockerfile-generator.ts
import type { DockerConfig } from '../schemas/docker.config';

export function generateDockerfile(config: DockerConfig): string {
  const parts: string[] = [];

  // Base image
  parts.push(`FROM ${config.baseImage.name}:${config.baseImage.tag}`);

  // Proxy settings
  if (config.proxySettings.httpProxy) {
    parts.push(`ENV HTTP_PROXY=${config.proxySettings.httpProxy}`);
    parts.push(`ENV http_proxy=${config.proxySettings.httpProxy}`);
  }

  // Package installation
  if (config.osPackages.length > 0) {
    const installCommand = getPackageInstallCommand(config.packageManager, config.osPackages);
    parts.push(installCommand);
  }

  // Add more sections based on config...

  return parts.join('\n\n');
}

function getPackageInstallCommand(manager: string, packages: string[]): string {
  const commands = {
    pacman: `RUN pacman -Syu --noconfirm ${packages.join(' ')}`,
    apt: `RUN apt-get update && apt-get install -y ${packages.join(' ')}`,
    apk: `RUN apk add --no-cache ${packages.join(' ')}`
  };

  return commands[manager] || commands.pacman;
}
```




#### dockerfile-generator.ts

```typescript
#!/usr/bin/env bun

import { consola } from 'consola';
import { defineCommand } from 'citty';
import { defineConfig } from 'c12';
import { Ollama } from 'ollama';
import { AnthropicClient } from '@anthropic-ai/sdk';
import { DockerConfigSchema } from './src/schemas/docker.config';
import { parseExistingDocker } from './src/utils/docker-parser';
import { generateDockerfile } from './src/generators/dockerfile-generator';

const main = defineCommand({
  meta: {
    name: 'dockerfile-generator',
    description: 'Generate Dockerfile from configuration'
  },
  args: {
    source: {
      type: 'string',
      description: 'Existing Dockerfile or container name',
      required: false
    }
  },
  async run({ args }) {
    try {
      // Step 1: Parse existing configuration
      const existingConfig = args.source
        ? await parseExistingDocker(args.source)
        : {};

      // Step 2: Prompt for configuration
      const config = await promptForConfig(existingConfig);

      // Step 3: Save configuration
      await saveConfig(config);

      // Step 4: Generate Dockerfile
      const useAI = await consola.confirm('Use AI to generate Dockerfile?');
      const dockerfile = useAI
        ? await generateDockerfileWithAI(config)
        : generateDockerfile(config);

      // Step 5: Save Dockerfile
      await Bun.write('Dockerfile', dockerfile);
      consola.success('Dockerfile generated successfully!');

    } catch (error) {
      consola.error('Error:', error);
      process.exit(1);
    }
  }
});

async function promptForConfig(existing = {}) {
  const config = {};

  for (const [key, schema] of Object.entries(DockerConfigSchema.shape)) {
    const defaultValue = existing[key] || schema._def.defaultValue;
    const description = schema.description;

    if (schema instanceof z.ZodArray) {
      config[key] = await consola.multiselect({
        message: description,
        options: defaultValue || []
      });
    } else {
      config[key] = await consola.prompt({
        type: 'text',
        message: description,
        initial: defaultValue
      });
    }
  }

  return config;
}

async function saveConfig(config) {
  await defineConfig({
    name: 'docker',
    defaults: config,
    layers: [{
      config,
      configFile: './docker.config.ts'
    }]
  });
}

async function generateDockerfileWithAI(config) {
  const aiProvider = await consola.select('Choose AI provider:', [
    'Ollama',
    'Claude'
  ]);

  const prompt = `Generate a Dockerfile with these requirements:
    ${JSON.stringify(config, null, 2)}`;

  switch (aiProvider) {
    case 'Ollama':
      const ollama = new Ollama();
      const response = await ollama.generate({
        model: 'codellama',
        prompt
      });
      return response.text;

    case 'Claude':
      const claude = new AnthropicClient({
        apiKey: process.env.ANTHROPIC_API_KEY
      });
      const completion = await claude.messages.create({
        model: 'claude-3-sonnet-20240229',
        max_tokens: 4096,
        messages: [{
          role: 'user',
          content: prompt
        }]
      });
      return completion.content[0].text;
  }
}

main.parse(process.argv);
```

























`src/schemas/docker.config.ts`:

```typescript
import { z } from 'zod';

export const ContainerRegistrySchema = z.object({
  url: z.string().url().describe('Container registry URL'),
  username: z.string().optional().describe('Registry username'),
  password: z.string().optional().describe('Registry password')
}).describe('Container registry configuration');

export const BaseImageSchema = z.object({
  name: z.string().default('archlinux').describe('Base image name'),
  tag: z.string().default('latest').describe('Base image tag')
}).describe('Base image configuration');

export const ProxySettingsSchema = z.object({
  httpProxy: z.string().optional().describe('HTTP proxy URL'),
  httpsProxy: z.string().optional().describe('HTTPS proxy URL'),
  noProxy: z.string().optional().describe('No proxy list')
}).describe('Proxy settings');

export const PackageManagerSchema = z.enum(['pacman', 'apt', 'apk', 'yum', 'dnf'])
  .describe('Package manager');

export const OSPackagesSchema = z.array(
  z.string()
).describe('OS packages to install');

// Add more schemas for other sections...

export const DockerConfigSchema = z.object({
  containerRegistry: ContainerRegistrySchema,
  baseImage: BaseImageSchema,
  proxySettings: ProxySettingsSchema,
  packageManager: PackageManagerSchema,
  osPackages: OSPackagesSchema,
  // Include other schemas...
}).describe('Complete Docker configuration');

export type DockerConfig = z.infer<typeof DockerConfigSchema>;
```


```typescript
// src/utils/docker-parser.ts
import { $ } from 'bun';
import type { DockerConfig } from '../schemas/docker.config';

export async function parseExistingDocker(source: string): Promise<Partial<DockerConfig>> {
  if (source.includes('Dockerfile')) {
    return parseDockerfile(source);
  } else {
    return parseContainer(source);
  }
}

async function parseDockerfile(path: string): Promise<Partial<DockerConfig>> {
  const content = await Bun.file(path).text();

  const baseImage = content.match(/FROM\s+([^\s]+)/)?.[1]?.split(':') || [];
  const packages = content.match(/RUN\s+(pacman|apt-get|apk)\s+install\s+([^\n]+)/)?.[2]?.split(/\s+/) || [];

  return {
    baseImage: {
      name: baseImage[0] || 'archlinux',
      tag: baseImage[1] || 'latest'
    },
    osPackages: packages
  };
}

async function parseContainer(name: string): Promise<Partial<DockerConfig>> {
  try {
    const { stdout } = await $`docker inspect ${name}`;
    const info = JSON.parse(stdout)[0];

    return {
      baseImage: {
        name: info.Config.Image.split(':')[0],
        tag: info.Config.Image.split(':')[1] || 'latest'
      },
      // Extract more configuration...
    };
  } catch (error) {
    console.error('Error inspecting container:', error);
    return {};
  }
}
```

```typescript
// src/generators/dockerfile-generator.ts
import type { DockerConfig } from '../schemas/docker.config';

export function generateDockerfile(config: DockerConfig): string {
  const parts: string[] = [];

  // Base image
  parts.push(`FROM ${config.baseImage.name}:${config.baseImage.tag}`);

  // Proxy settings
  if (config.proxySettings.httpProxy) {
    parts.push(`ENV HTTP_PROXY=${config.proxySettings.httpProxy}`);
    parts.push(`ENV http_proxy=${config.proxySettings.httpProxy}`);
  }

  // Package installation
  if (config.osPackages.length > 0) {
    const installCommand = getPackageInstallCommand(config.packageManager, config.osPackages);
    parts.push(installCommand);
  }

  // Add more sections based on config...

  return parts.join('\n\n');
}

function getPackageInstallCommand(manager: string, packages: string[]): string {
  const commands = {
    pacman: `RUN pacman -Syu --noconfirm ${packages.join(' ')}`,
    apt: `RUN apt-get update && apt-get install -y ${packages.join(' ')}`,
    apk: `RUN apk add --no-cache ${packages.join(' ')}`
  };

  return commands[manager] || commands.pacman;
}
```

4. Create the main script `dockerfile-generator.ts`:

```typescript
#!/usr/bin/env bun

import { consola } from 'consola';
import { defineCommand } from 'citty';
import { defineConfig } from 'c12';
import { Ollama } from 'ollama';
import { AnthropicClient } from '@anthropic-ai/sdk';
import { DockerConfigSchema } from './src/schemas/docker.config';
import { parseExistingDocker } from './src/utils/docker-parser';
import { generateDockerfile } from './src/generators/dockerfile-generator';

const main = defineCommand({
  meta: {
    name: 'dockerfile-generator',
    description: 'Generate Dockerfile from configuration'
  },
  args: {
    source: {
      type: 'string',
      description: 'Existing Dockerfile or container name',
      required: false
    }
  },
  async run({ args }) {
    try {
      // Step 1: Parse existing configuration
      const existingConfig = args.source
        ? await parseExistingDocker(args.source)
        : {};

      // Step 2: Prompt for configuration
      const config = await promptForConfig(existingConfig);

      // Step 3: Save configuration
      await saveConfig(config);

      // Step 4: Generate Dockerfile
      const useAI = await consola.confirm('Use AI to generate Dockerfile?');
      const dockerfile = useAI
        ? await generateDockerfileWithAI(config)
        : generateDockerfile(config);

      // Step 5: Save Dockerfile
      await Bun.write('Dockerfile', dockerfile);
      consola.success('Dockerfile generated successfully!');

    } catch (error) {
      consola.error('Error:', error);
      process.exit(1);
    }
  }
});

async function promptForConfig(existing = {}) {
  const config = {};

  for (const [key, schema] of Object.entries(DockerConfigSchema.shape)) {
    const defaultValue = existing[key] || schema._def.defaultValue;
    const description = schema.description;

    if (schema instanceof z.ZodArray) {
      config[key] = await consola.multiselect({
        message: description,
        options: defaultValue || []
      });
    } else {
      config[key] = await consola.prompt({
        type: 'text',
        message: description,
        initial: defaultValue
      });
    }
  }

  return config;
}

async function saveConfig(config) {
  await defineConfig({
    name: 'docker',
    defaults: config,
    layers: [{
      config,
      configFile: './docker.config.ts'
    }]
  });
}

async function generateDockerfileWithAI(config) {
  const aiProvider = await consola.select('Choose AI provider:', [
    'Ollama',
    'Claude'
  ]);

  const prompt = `Generate a Dockerfile with these requirements:
    ${JSON.stringify(config, null, 2)}`;

  switch (aiProvider) {
    case 'Ollama':
      const ollama = new Ollama();
      const response = await ollama.generate({
        model: 'codellama',
        prompt
      });
      return response.text;

    case 'Claude':
      const claude = new AnthropicClient({
        apiKey: process.env.ANTHROPIC_API_KEY
      });
      const completion = await claude.messages.create({
        model: 'claude-3-sonnet-20240229',
        max_tokens: 4096,
        messages: [{
          role: 'user',
          content: prompt
        }]
      });
      return completion.content[0].text;
  }
}

main.parse(process.argv);
```
