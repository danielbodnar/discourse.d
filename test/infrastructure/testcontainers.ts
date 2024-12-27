// src/test/infrastructure/testcontainers.ts
import { GenericContainer, Network, Wait } from "testcontainers";
import { LocalStackContainer } from "@testcontainers/localstack";
import { PostgreSqlContainer } from "@testcontainers/postgresql";
import { RedisContainer } from "@testcontainers/redis";

export class DiscourseTestEnvironment {
  private network: Network;
  private postgres: PostgreSqlContainer;
  private redis: RedisContainer;
  private localstack: LocalStackContainer;
  private discourse: GenericContainer;

  constructor() {
    this.network = new Network();
  }

  async start() {
    // Start LocalStack
    this.localstack = await new LocalStackContainer()
      .withNetwork(this.network)
      .withServices(["s3", "ses"])
      .withInitializer([
        {
          service: "s3",
          command: ["aws", "s3", "mb", "s3://discourse-uploads"],
        },
      ])
      .start();

    // Start PostgreSQL
    this.postgres = await new PostgreSqlContainer()
      .withNetwork(this.network)
      .withDatabase("discourse_test")
      .withUsername("discourse")
      .withPassword("discourse")
      .start();

    // Start Redis
    this.redis = await new RedisContainer().withNetwork(this.network).start();

    // Start Discourse
    this.discourse = await new GenericContainer("discourse/base:3.2.1")
      .withNetwork(this.network)
      .withEnvironment({
        RAILS_ENV: "test",
        DISCOURSE_DB_HOST: this.postgres.getHost(),
        DISCOURSE_DB_PORT: this.postgres.getPort(),
        DISCOURSE_DB_NAME: "discourse_test",
        DISCOURSE_DB_USERNAME: "discourse",
        DISCOURSE_DB_PASSWORD: "discourse",
        DISCOURSE_REDIS_HOST: this.redis.getHost(),
        DISCOURSE_REDIS_PORT: this.redis.getPort(),
        AWS_ENDPOINT: this.localstack.getEndpoint(),
        AWS_ACCESS_KEY_ID: "test",
        AWS_SECRET_ACCESS_KEY: "test",
        S3_BUCKET: "discourse-uploads",
      })
      .withExposedPorts(3000)
      .withWaitStrategy(Wait.forHttp("/"))
      .start();
  }

  async stop() {
    await this.discourse.stop();
    await this.redis.stop();
    await this.postgres.stop();
    await this.localstack.stop();
    await this.network.stop();
  }

  getDiscourseUrl() {
    return `http://${this.discourse.getHost()}:${this.discourse.getMappedPort(3000)}`;
  }
}
