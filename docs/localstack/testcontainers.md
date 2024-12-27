# LocalStack and TestContainers Documentation

## Overview
Integration testing setup for Discourse using LocalStack for AWS service emulation and TestContainers for containerized test dependencies.

## Table of Contents
1. [LocalStack Configuration](#localstack-configuration)
2. [TestContainers Setup](#testcontainers-setup)
3. [Integration Tests](#integration-tests)
4. [CI/CD Integration](#cicd-integration)

## LocalStack Configuration

### 1. Service Definition
```typescript
// src/test/infrastructure/localstack.ts
import { LocalStackContainer } from '@testcontainers/localstack';

export class DiscourseLocalStack {
  private container: LocalStackContainer;

  async start() {
    this.container = await new LocalStackContainer()
      .withServices(['s3', 'ses', 'sqs'])
      .withInitializer([
        {
          service: 's3',
          command: [
            'aws',
            's3api',
            'create-bucket',
            '--bucket', 'discourse-uploads'
          ]
        },
        {
          service: 'ses',
          command: [
            'aws',
            'ses',
            'verify-email-identity',
            '--email-address', 'no-reply@discourse.test'
          ]
        }
      ])
      .start();
  }

  getEndpoint() {
    return this.container.getEndpoint();
  }

  getCredentials() {
    return {
      accessKeyId: 'test',
      secretAccessKey: 'test',
      region: 'us-east-1'
    };
  }
}
```

### 2. AWS Service Configuration
```typescript
// src/test/infrastructure/aws-services.ts
import { S3Client } from '@aws-sdk/client-s3';
import { SESClient } from '@aws-sdk/client-ses';

export class AWSServices {
  private s3: S3Client;
  private ses: SESClient;

  constructor(endpoint: string, credentials: any) {
    const config = {
      endpoint,
      credentials,
      region: 'us-east-1',
      forcePathStyle: true
    };

    this.s3 = new S3Client(config);
    this.ses = new SESClient(config);
  }

  async setupTestBucket() {
    // Implementation
  }

  async setupTestEmailIdentity() {
    // Implementation
  }
}
```

## TestContainers Setup

### 1. Base Test Environment
```typescript
// src/test/infrastructure/test-environment.ts
import { PostgreSqlContainer } from '@testcontainers/postgresql';
import { RedisContainer } from '@testcontainers/redis';
import { GenericContainer } from 'testcontainers';
import { DiscourseLocalStack } from './localstack';

export class DiscourseTestEnvironment {
  private postgres: PostgreSqlContainer;
  private redis: RedisContainer;
  private localstack: DiscourseLocalStack;
  private discourse: GenericContainer;

  async start() {
    await Promise.all([
      this.startPostgres(),
      this.startRedis(),
      this.startLocalStack()
    ]);

    await this.startDiscourse();
  }

  private async startPostgres() {
    this.postgres = await new PostgreSqlContainer()
      .withDatabase('discourse_test')
      .withUsername('discourse')
      .withPassword('discourse')
      .start();
  }

  private async startRedis() {
    this.redis = await new RedisContainer().start();
  }

  private async startLocalStack() {
    this.localstack = new DiscourseLocalStack();
    await this.localstack.start();
  }

  private async startDiscourse() {
    this.discourse = await new GenericContainer('discourse/base:3.2.1')
      .withEnvironment({
        RAILS_ENV: 'test',
        DISCOURSE_DB_HOST: this.postgres.getHost(),
        DISCOURSE_DB_PORT: this.postgres.getPort().toString(),
        DISCOURSE_DB_NAME: 'discourse_test',
        DISCOURSE_DB_USERNAME: 'discourse',
        DISCOURSE_DB_PASSWORD: 'discourse',
        DISCOURSE_REDIS_HOST: this.redis.getHost(),
        DISCOURSE_REDIS_PORT: this.redis.getPort().toString(),
        AWS_ENDPOINT: this.localstack.getEndpoint(),
        AWS_ACCESS_KEY_ID: 'test',
        AWS_SECRET_ACCESS_KEY: 'test'
      })
      .withExposedPorts(3000)
      .start();
  }

  async stop() {
    await Promise.all([
      this.discourse.stop(),
      this.postgres.stop(),
      this.redis.stop(),
      this.localstack.stop()
    ]);
  }

  getDiscourseUrl() {
    return `http://${this.discourse.getHost()}:${this.discourse.getMappedPort(3000)}`;
  }
}
```

### 2. Test Helpers
```typescript
// src/test/helpers/test-helper.ts
import { DiscourseTestEnvironment } from '../infrastructure/test-environment';

export class TestHelper {
  private static environment: DiscourseTestEnvironment;

  static async setupTestEnvironment() {
    this.environment = new DiscourseTestEnvironment();
    await this.environment.start();
  }

  static async teardownTestEnvironment() {
    await this.environment.stop();
  }

  static getEnvironment() {
    return this.environment;
  }
}
```

## Integration Tests

### 1. User Management Tests
```typescript
// src/test/integration/user.test.ts
import { TestHelper } from '../helpers/test-helper';
import axios from 'axios';

describe('User Management', () => {
  beforeAll(async () => {
    await TestHelper.setupTestEnvironment();
  });

  afterAll(async () => {
    await TestHelper.teardownTestEnvironment();
  });

  test('user registration with email verification', async () => {
    const env = TestHelper.getEnvironment();
    // Test implementation
  });
});
```

### 2. File Upload Tests
```typescript
// src/test/integration/uploads.test.ts
import { TestHelper } from '../helpers/test-helper';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

describe('File Uploads', () => {
  let s3Client: S3Client;

  beforeAll(async () => {
    await TestHelper.setupTestEnvironment();
    // Initialize S3 client
  });

  test('upload to S3', async () => {
    // Test implementation
  });
});
```

## CI/CD Integration

### 1. GitHub Actions
```yaml
# .github/workflows/integration-tests.yml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Run integration tests
        run: npm run test:integration
```

### 2. Jest Configuration
```javascript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/test/integration/**/*.test.ts'],
  setupFilesAfterEnv: ['<rootDir>/test/setup.ts'],
  globalSetup: '<rootDir>/test/global-setup.ts',
  globalTeardown: '<rootDir>/test/global-teardown.ts'
};
```

## Test Data Management

### 1. Fixtures
```typescript
// src/test/fixtures/users.ts
export const testUsers = [
  {
    email: 'test@example.com',
    username: 'testuser',
    password: 'password123'
  }
];
```

### 2. Database Seeding
```typescript
// src/test/helpers/database-helper.ts
export class DatabaseHelper {
  static async seedTestData() {
    // Implementation
  }

  static async cleanTestData() {
    // Implementation
  }
}
```

## Best Practices

### 1. Test Organization
```typescript
// Group tests by feature
describe('User Management', () => {
  describe('Registration', () => {
    // Registration tests
  });

  describe('Authentication', () => {
    // Authentication tests
  });
});
```

### 2. Resource Cleanup
```typescript
// Ensure proper cleanup after tests
afterEach(async () => {
  await DatabaseHelper.cleanTestData();
});

afterAll(async () => {
  await TestHelper.teardownTestEnvironment();
});
```

### 3. Error Handling
```typescript
// src/test/helpers/error-handler.ts
export class TestErrorHandler {
  static async captureError(fn: () => Promise<void>) {
    try {
      await fn();
    } catch (error) {
      // Handle and log test errors
    }
  }
}
```

## Performance Optimization

### 1. Container Reuse
```typescript
// Reuse containers across tests
beforeAll(async () => {
  if (!TestHelper.isEnvironmentRunning()) {
    await TestHelper.setupTestEnvironment();
  }
});
```

### 2. Parallel Test Execution
```typescript
// jest.config.js
module.exports = {
  maxWorkers: 4,
  maxConcurrency: 2
};
```

## Debugging

### 1. Container Logs
```typescript
// src/test/helpers/log-helper.ts
export class LogHelper {
  static async getContainerLogs(container: any) {
    const logs = await container.logs();
    console.log(logs);
  }
}
```

### 2. Test Debugging
```typescript
// Enable debug mode
process.env.DEBUG = 'testcontainers:*';
```
