Thank you for the detailed outline! I'll help create a more complete implementation of this Dockerfile generator script. Let's break it down into multiple files for better organization:

1. First, create a `package.json`:

```json
{
  "name": "dockerfile-generator",
  "module": "index.ts",
  "type": "module",
  "dependencies": {
    "@anthropic-ai/sdk": "^0.17.1",
    "c12": "^1.5.1",
    "citty": "^0.1.5",
    "consola": "^3.2.3",
    "llamaindex": "^0.1.11",
    "magicast": "^0.3.3",
    "ollama": "^0.4.9",
    "zod": "^3.22.4",
    "zod-to-json-schema": "^3.22.3"
  },
  "devDependencies": {
    "bun-types": "latest"
  }
}
```

2. Create `src/schemas/index.ts` for our Zod schemas:

```typescript
import { z } from 'zod';

export const ContainerRegistrySchema = z.object({
  url: z.string().url().describe('Container registry URL'),
  username: z.string().optional().describe('Registry username'),
  password: z.string().optional().describe('Registry password'),
}).describe('Container Registry Configuration');

export const BaseImageSchema = z.object({
  name: z.string().default('archlinux').describe('Base image name'),
  tag: z.string().default('latest').describe('Base image tag'),
  digest: z.string().optional().describe('Base image digest (sha256)'),
}).describe('Base Image Configuration');

export const BuildArgsSchema = z.array(
  z.object({
    name: z.string().describe('Build argument name'),
    value: z.string().describe('Build argument value'),
    secret: z.boolean().default(false).describe('Is this a secret build arg?'),
  })
).describe('Build Arguments');

export const EnvVarsSchema = z.array(
  z.object({
    name: z.string().describe('Environment variable name'),
    value: z.string().describe('Environment variable value'),
    secret: z.boolean().default(false).describe('Is this a secret env var?'),
  })
).describe('Environment Variables');

export const ProxyConfigSchema = z.object({
  http_proxy: z.string().optional().describe('HTTP proxy URL'),
  https_proxy: z.string().optional().describe('HTTPS proxy URL'),
  no_proxy: z.string().optional().describe('No proxy list'),
}).describe('Proxy Configuration');

export const PackagesSchema = z.object({
  manager: z.enum(['pacman', 'apt', 'apk', 'dnf', 'yum']).describe('Package manager'),
  packages: z.array(z.string()).describe('Packages to install'),
}).describe('OS Packages Configuration');

export const SourcesSchema = z.array(
  z.object({
    type: z.enum(['git', 'local', 'url']).describe('Source type'),
    location: z.string().describe('Source location'),
    destination: z.string().describe('Destination in container'),
  })
).describe('Application Sources');

export const UserGroupSchema = z.object({
  user: z.string().default('nobody').describe('Container user'),
  group: z.string().default('nobody').describe('Container group'),
  uid: z.number().optional().describe('User ID'),
  gid: z.number().optional().describe('Group ID'),
}).describe('User and Group Configuration');

export const VolumesSchema = z.array(
  z.object({
    source: z.string().describe('Volume source'),
    target: z.string().describe('Volume target'),
    type: z.enum(['bind', 'volume', 'tmpfs']).default('volume'),
  })
).describe('Volumes Configuration');

export const PortsSchema = z.array(
  z.object({
    container: z.number().describe('Container port'),
    host: z.number().optional().describe('Host port'),
    protocol: z.enum(['tcp', 'udp']).default('tcp'),
  })
).describe('Exposed Ports Configuration');

export const DockerfileConfigSchema = z.object({
  containerRegistry: ContainerRegistrySchema,
  baseImage: BaseImageSchema,
  buildArgs: BuildArgsSchema,
  envVars: EnvVarsSchema,
  proxy: ProxyConfigSchema,
  packages: PackagesSchema,
  sources: SourcesSchema,
  userGroup: UserGroupSchema,
  volumes: VolumesSchema,
  ports: PortsSchema,
}).describe('Complete Dockerfile Configuration');
```

3. Create `src/utils/docker-parser.ts` for parsing existing Dockerfiles:

```typescript
import { readFileSync } from 'node:fs';
import { $ } from 'bun';

export class DockerParser {
  static async parseDockerfile(path: string) {
    const content = readFileSync(path, 'utf-8');
    return this.parseDockerfileContent(content);
  }

  static async parseDockerfileContent(content: string) {
    const lines = content.split('\n');
    const config: any = {
      baseImage: { name: '', tag: '' },
      envVars: [],
      ports: [],
      volumes: [],
    };

    for (const line of lines) {
      if (line.startsWith('FROM ')) {
        const [_, image] = line.split(' ');
        const [name, tag] = image.split(':');
        config.baseImage = { name, tag: tag || 'latest' };
      }
      // Add more parsing logic for other Dockerfile instructions
    }

    return config;
  }

  static async inspectContainer(containerIdOrName: string) {
    const { stdout } = await $`docker inspect ${containerIdOrName}`;
    const inspection = JSON.parse(stdout);
    // Parse the inspection output and return config
    return {};
  }
}
```

4. Create the main script `src/index.ts`:

```typescript
#!/usr/bin/env bun
import { defineCommand, runMain } from 'citty';
import { consola } from 'consola';
import { defineConfig } from 'c12';
import { DockerfileConfigSchema } from './schemas';
import { DockerParser } from './utils/docker-parser';
import { Ollama } from 'ollama';
import { AnthropicClient } from '@anthropic-ai/sdk';

const main = defineCommand({
  meta: {
    name: 'dockerfile-generator',
    description: 'Generate Dockerfile from configuration',
  },
  args: {
    source: {
      type: 'string',
      description: 'Existing Dockerfile, container, or image to analyze',
      required: false,
    },
    ai: {
      type: 'boolean',
      description: 'Use AI to generate Dockerfile',
      default: false,
    },
  },
  async run({ args }) {
    let config: any = {};

    if (args.source) {
      if (args.source.endsWith('Dockerfile')) {
        config = await DockerParser.parseDockerfile(args.source);
      } else {
        config = await DockerParser.inspectContainer(args.source);
      }
    }

    // Prompt for missing configurations
    for (const [key, schema] of Object.entries(DockerfileConfigSchema.shape)) {
      if (!config[key]) {
        config[key] = await promptForConfig(schema, {});
      }
    }

    // Save configuration
    await defineConfig({
      name: 'docker',
      defaults: config,
      layers: [{
        configFile: './docker.config.ts',
      }],
    });

    // Generate Dockerfile
    let dockerfile: string;
    if (args.ai) {
      dockerfile = await generateDockerfileWithAI(config);
    } else {
      dockerfile = generateDockerfile(config);
    }

    await Bun.write('Dockerfile', dockerfile);
    consola.success('Dockerfile generated successfully!');
  },
});

async function promptForConfig(schema: any, existing: any) {
  // Implementation of config prompting
}

function generateDockerfile(config: any): string {
  // Implementation of Dockerfile generation
}

async function generateDockerfileWithAI(config: any): Promise<string> {
  // Implementation of AI-assisted generation
}

runMain(main);
```

5. Make the script executable:
```bash
chmod +x src/index.ts
```

This implementation provides a solid foundation for a Dockerfile generator. To use it:

```bash
# Install dependencies
bun install

# Run the generator
./src/index.ts

# Or with an existing Dockerfile
./src/index.ts --source ./path/to/Dockerfile

# Or with AI assistance
./src/index.ts --ai
```

The script can be further enhanced by:

1. Adding more detailed parsing of existing Dockerfiles
2. Implementing more sophisticated AI prompts
3. Adding validation for generated Dockerfiles
4. Supporting different output formats (Dockerfile, OCI rootfs)
5. Adding support for multi-stage builds
6. Implementing configuration presets
7. Adding support for container scanning and security checks

Would you like me to expand on any particular aspect of this implementation?
