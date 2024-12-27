import { z } from 'zod';

export const kubernetesConfig = z.object({
  deployment: {
    name: z.string(),
    replicas: z.number().min(1),
    image: z.string(),
    tag: z.string(),
    pullPolicy: z.enum(['Always', 'IfNotPresent', 'Never']),
    resources: z.object({
      requests: z.object({
        cpu: z.string(),
        memory: z.string()
      }),
      limits: z.object({
        cpu: z.string(),
        memory: z.string()
      })
    }),
    securityContext: z.object({
      runAsUser: z.number(),
      runAsGroup: z.number(),
      readOnlyRootFilesystem: z.boolean(),
      allowPrivilegeEscalation: z.boolean()
    })
  },
  volumes: z.array(z.object({
    name: z.string(),
    mountPath: z.string(),
    persistentVolumeClaim: z.object({
      claimName: z.string(),
      storageClass: z.string().optional(),
      size: z.string()
    })
  })),
  ingress: z.object({
    enabled: z.boolean(),
    annotations: z.record(z.string()),
    hosts: z.array(z.object({
      host: z.string(),
      paths: z.array(z.string())
    })),
    tls: z.array(z.object({
      secretName: z.string(),
      hosts: z.array(z.string())
    })).optional()
  })
});