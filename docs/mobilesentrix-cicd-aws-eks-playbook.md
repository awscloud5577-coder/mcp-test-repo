# Mobilesentrix CI/CD + AWS EKS Implementation Story, Interview Prep, and Hands-on Lab

## 1) Detailed implementation story (interview-ready narrative)

Use this as a polished, first-person story in interviews.

### Business context
At Mobilesentrix, our engineering teams were shipping multiple services with inconsistent deployment flows and high manual effort. Build queues were growing, deployment confidence was low, and infra cost was rising as traffic patterns changed. The business expectation was to improve release velocity while meeting production SLAs and maintaining security posture.

### Problem statement
We had three major technical problems:
1. **Inconsistent CI/CD and deployment patterns** across services.
2. **Cluster reliability issues** due to uneven resource sizing and reactive scaling.
3. **High AWS spend** because scaling and node provisioning were not cost-aware.

### What I designed
I designed a platform based on:
- **AWS EKS (multi-AZ, private worker nodes)** for production Kubernetes.
- **Jenkins on Kubernetes with dynamic agents** for elastic CI workload execution.
- **Kaniko-based image builds** to eliminate Docker daemon dependency in CI jobs.
- **Karpenter + Spot strategy** for cost-aware, demand-driven node provisioning.
- **HPA + VPA + optional KEDA** for workload autoscaling at app layer.
- **Observability stack (Prometheus, Grafana, CloudWatch)** with actionable SLO alerts.
- **Security hardening**: private subnets, VPC endpoints, IAM least privilege, KMS, Secrets Manager.

### Execution strategy
I split execution into phases to reduce delivery risk:

#### Phase A: Platform baseline
- Built VPC with private/public subnet separation across 3 AZs.
- Provisioned EKS with managed node groups for baseline/control workloads.
- Enabled cluster logging and OIDC integration for IRSA.

#### Phase B: CI modernization
- Deployed Jenkins with Kubernetes plugin and pod templates.
- Moved from static Jenkins workers to dynamic ephemeral pods.
- Standardized shared libraries for pipeline consistency.

#### Phase C: Secure build pipeline
- Implemented Kaniko jobs in agent pods for image builds.
- Integrated image scanning and signed image promotion logic.
- Restricted registry and secret access using namespace/RBAC + IRSA.

#### Phase D: Reliability and scaling
- Added workload requests/limits based on measured usage.
- Implemented HPA policies and VPA in recommendation mode first.
- Introduced Karpenter provisioners/nodepools for right-sized compute.
- Added Spot diversification with interruption handling.

#### Phase E: Visibility and operations
- Set up Prometheus + Grafana dashboards (API latency, saturation, restart rate).
- Routed infra-level metrics/events into CloudWatch.
- Added alert thresholds tied to SLO error budgets, not only raw CPU/memory.

### Result framing (how to explain impact)
In interviews, state measurable outcomes with placeholders if needed:
- Deployment lead time reduced from **X hours to Y minutes**.
- Build queue wait time reduced by **A%** with dynamic agents.
- Failed deployments dropped by **B%** via standard pipelines and safer rollouts.
- Infra cost reduced by **C%** using Karpenter + Spot mix.
- MTTR improved by **D%** using better alerts and dashboards.

### Ownership signals to emphasize
- I drove both **platform engineering** and **delivery enablement**.
- I collaborated with developers to define default templates/guardrails.
- I established runbooks and SRE-style operational reviews after incidents.

---

## 2) Proactive counter-questions a technical interviewer may ask

Below are likely follow-ups and how to answer.

### Architecture and reliability
1. **Why EKS over self-managed Kubernetes?**
   - Managed control plane reduced operational burden, improved upgrade reliability, and integrated cleanly with IAM, CloudWatch, and VPC networking.

2. **How did you design multi-AZ resilience?**
   - Spread node groups across AZs, used topology spread constraints/anti-affinity for critical pods, and validated zonal failure behavior.

3. **How did you handle cluster upgrades safely?**
   - Blue/green node group strategy + pod disruption budgets + staged rollout (non-prod → prod canary namespaces).

4. **How did you prevent noisy-neighbor problems?**
   - Namespace-level quotas/limit ranges, mandatory requests/limits, and node isolation for critical workloads.

### CI/CD design
5. **Why Jenkins instead of GitHub Actions/GitLab CI?**
   - Existing enterprise workflows/plugins and mature shared library usage justified keeping Jenkins while modernizing execution model.

6. **How did dynamic agents improve throughput?**
   - Pods are created per build with task-specific resources, eliminating static worker contention and reducing idle infra.

7. **How did you secure Jenkins-to-cluster and registry access?**
   - IRSA-backed service accounts, minimal RBAC, short-lived tokens, and segregated credentials by environment.

8. **How did you make pipelines reusable?**
   - Shared libraries + common Jenkinsfile stages + parameterized deployment templates.

### Security and compliance
9. **How was secret management implemented?**
   - AWS Secrets Manager for central secret storage, synchronized into workloads through controlled access patterns and audit trails.

10. **How did you enforce least privilege in AWS?**
    - Granular IAM roles per workload using IRSA, explicit deny where needed, and regular policy review.

11. **How was encryption handled?**
    - KMS for data-at-rest in EBS/Secrets/logs where supported; TLS everywhere for in-transit paths.

12. **How did you secure container builds with Kaniko?**
    - Rootless build context patterns where possible, no privileged Docker daemon, restricted egress, signed provenance.

### Scaling and cost
13. **How did you avoid overprovisioning with HPA/VPA/Karpenter together?**
    - VPA recommendations informed request tuning; HPA scaled replicas on metrics; Karpenter handled node supply. Guardrails prevented feedback loops.

14. **How did you control Spot interruption risk?**
    - Diversified instance families/AZs, interruption handling hooks, graceful pod eviction, and on-demand fallback pools.

15. **What was your Karpenter bin-packing strategy?**
    - Flexible instance constraints with priorities for cost and availability, plus right-sized pod requests to improve scheduling efficiency.

16. **When would you use KEDA vs HPA?**
    - HPA for CPU/memory/basic custom metrics; KEDA for event-driven triggers like queue depth, Kafka lag, or cloud events.

### Observability and incident response
17. **What key alerts did you define?**
    - SLO burn alerts, pod crash loops, high latency, saturation, and control-plane/node health indicators.

18. **How did you reduce alert fatigue?**
    - Multi-window burn-rate alerts, severity tuning, inhibition rules, and ownership routing.

19. **How did you debug intermittent deployment failures?**
    - Correlated Jenkins stage logs with Kubernetes events, admission controller logs, and container runtime pull errors.

### Operational maturity
20. **What would you improve next?**
    - Progressive delivery (Argo Rollouts/Flagger), policy-as-code (OPA), stronger SBOM/signing, and disaster recovery game days.

---

## 3) Advanced scenario-based interview drills

### Scenario A: Build storm during release day
- **Symptom**: 300 queued builds, slow deployments.
- **Approach**:
  1. Check Jenkins executor saturation and pod provisioning latency.
  2. Review cluster pending pods and unschedulable reasons.
  3. Validate Karpenter provisioning limits and subnet/IP exhaustion.
  4. Split heavy pipelines (build/test/security scan) into parallel stages.
  5. Add cache strategy (dependency and layer caching).

### Scenario B: Spot interruptions cause API latency spikes
- **Symptom**: p95 latency spikes at random times.
- **Approach**:
  1. Correlate interruption notices with HPA/Karpenter events.
  2. Increase replica buffer and tune PDB to preserve quorum.
  3. Keep critical workloads on mixed or on-demand node pools.
  4. Use priority classes and pre-warm minimum capacity for critical APIs.

### Scenario C: Security asks for supply-chain hardening
- **Symptom**: Need stronger evidence and artifact trust.
- **Approach**:
  1. Generate SBOM per image.
  2. Enforce signature verification at admission.
  3. Block critical CVEs pre-prod.
  4. Store provenance metadata and trace deployment to commit SHA.

### Scenario D: Memory OOM loops after feature launch
- **Symptom**: pods repeatedly OOMKilled.
- **Approach**:
  1. Compare old/new heap profiles and request/limit settings.
  2. Apply VPA recommendations and retest load.
  3. Add JVM/runtime tuning and canary rollout gates.
  4. Alert on memory working set growth rate.

---

## 4) Hands-on lab (Terraform + Kubernetes + Jenkins dynamic agents)

> Goal: Build a reusable, production-minded platform **without eksctl**.

### 4.1 Lab outcomes
By the end, you will have:
- Terraform-managed AWS network + EKS foundation.
- Jenkins on Kubernetes using dynamic pod agents.
- Kaniko image build pipeline.
- HPA + VPA + Karpenter setup.
- Monitoring stack and sample workload deployment.

### 4.2 Prerequisites
- AWS account with admin/sandbox permissions.
- Terraform >= 1.6, kubectl, helm, awscli, jq.
- Route53/domain (optional for ingress).
- Container registry access (ECR recommended).

### 4.3 High-level architecture
1. Terraform provisions VPC, subnets, NAT, EKS, IAM, OIDC/IRSA basics.
2. Helm installs Jenkins and monitoring stack.
3. Jenkins dynamic agents run pipeline pods (Kaniko + kubectl tools).
4. Karpenter provisions nodes for unschedulable pods.
5. HPA/VPA/KEDA scale workloads; Prometheus/Grafana observe behavior.

---

## 5) Terraform implementation (dynamic + reusable)

Use the Terraform files under `infra/terraform` in this repository.

### 5.1 Initialization and apply
```bash
cd infra/terraform
terraform init
terraform plan -var-file=env/dev.tfvars
terraform apply -var-file=env/dev.tfvars
```

### 5.2 Design notes
- Variables are parameterized by environment, CIDR, AZ count, and tags.
- EKS addons and node groups are declared as maps for reuse.
- IRSA and cluster authentication are enabled for secure workload IAM.

---

## 6) Kubernetes configuration steps (automated path)

### Step 1: Configure kubeconfig
```bash
aws eks update-kubeconfig --name <cluster_name> --region <region>
kubectl get nodes
```

### Step 2: Install Jenkins (Helm)
```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
helm upgrade --install jenkins jenkins/jenkins \
  -n jenkins --create-namespace \
  -f k8s/jenkins/values.yaml
```

### Step 3: Install metrics-server and autoscalers
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl apply -f k8s/autoscaling/vpa-recommender.yaml
kubectl apply -f k8s/autoscaling/sample-hpa.yaml
```

### Step 4: Install Karpenter (example)
```bash
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --namespace karpenter --create-namespace \
  --set settings.clusterName=<cluster_name> \
  --set settings.clusterEndpoint=<cluster_endpoint> \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<karpenter_irsa_role_arn>

kubectl apply -f k8s/karpenter/ec2nodeclass.yaml
kubectl apply -f k8s/karpenter/nodepool.yaml
```

### Step 5: Install observability
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install kube-prom-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace
```

---

## 7) Manual practice path (so you can learn internals)

### 7.1 Manual AWS setup (learning mode)
1. Create VPC, subnets (public/private), route tables, IGW, NAT.
2. Create EKS cluster IAM role and node IAM role.
3. Create EKS cluster and managed node group in private subnets.
4. Enable OIDC provider and create IRSA roles manually.
5. Install aws-load-balancer-controller, metrics-server, and Karpenter.

### 7.2 Manual Jenkins dynamic agent setup
1. Deploy Jenkins via Helm or manifests.
2. Install Jenkins Kubernetes plugin.
3. Define cloud config:
   - Kubernetes URL/in-cluster
   - Jenkins URL
   - Namespace for agents
4. Add pod templates:
   - `jnlp` container
   - `kaniko` container
   - `kubectl` container
5. Run a test pipeline that spins an ephemeral agent pod and executes stages.

### 7.3 Manual pipeline verification checklist
- Verify pod lifecycle per build (`kubectl get pods -n jenkins -w`).
- Verify no long-lived static agents.
- Verify image push to ECR and deployment rollout success.

---

## 8) Jenkins dynamic agent and Kaniko pipeline blueprint

### 8.1 Example Jenkinsfile
```groovy
pipeline {
  agent none
  stages {
    stage('Build and Push') {
      agent {
        kubernetes {
          label 'kaniko-agent'
          defaultContainer 'kaniko'
          yamlFile 'k8s/jenkins/kaniko-pod.yaml'
        }
      }
      environment {
        IMAGE_REPO = "<account>.dkr.ecr.<region>.amazonaws.com/sample-app"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
      }
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor \
              --context $WORKSPACE \
              --dockerfile Dockerfile \
              --destination ${IMAGE_REPO}:${IMAGE_TAG}
          '''
        }
      }
    }

    stage('Deploy') {
      agent {
        kubernetes {
          label 'kubectl-agent'
          defaultContainer 'kubectl'
          yamlFile 'k8s/jenkins/kubectl-pod.yaml'
        }
      }
      steps {
        container('kubectl') {
          sh '''
            kubectl -n app set image deploy/sample-app sample-app=${IMAGE_REPO}:${IMAGE_TAG}
            kubectl -n app rollout status deploy/sample-app --timeout=180s
          '''
        }
      }
    }
  }
}
```

### 8.2 Why this is interview-strong
- Demonstrates ephemeral, least-privilege build workers.
- Separates build and deploy concerns.
- Shows scalable and secure CI execution pattern.

---

## 9) How to make the implementation better (next-step roadmap)

### Wave 1 (Immediate hardening)
1. Enforce Pod Security Standards and network policies.
2. Implement image signing and admission verification.
3. Introduce OPA Gatekeeper/Kyverno baseline policies.

### Wave 2 (Delivery safety)
1. Add canary/blue-green progressive delivery.
2. Add automated rollback on SLO burn alerts.
3. Add smoke + synthetic checks post-deployment.

### Wave 3 (Cost and performance)
1. Add workload-level cost dashboards (namespace/team).
2. Improve request-rightsizing automation from historical data.
3. Expand Spot diversification and fallback logic.

### Wave 4 (Resilience and DR)
1. Multi-region disaster recovery drills.
2. Backup and restore validation for stateful workloads.
3. Chaos testing and game days for critical services.

### Wave 5 (Platform productization)
1. Golden path templates for service onboarding.
2. Self-service deployment portal with guardrails.
3. SLO maturity per service and error-budget governance.

---

## 10) High-value “deep dive” interviewer questions (advanced)

1. How do you prevent HPA and VPA conflict in production?
2. What safeguards prevent Karpenter from launching overly expensive nodes?
3. How do you handle container image provenance and policy enforcement?
4. How do you implement blast-radius reduction for Jenkins shared libraries?
5. How do you test rollback automation before incidents happen?
6. What is your approach to API rate limits during large autoscaling events?
7. How do you detect and resolve subnet IP exhaustion in EKS?
8. How do you standardize SLOs across heterogeneous microservices?

---

## 11) Practice script for interviews (short version)

“I designed and operationalized a secure, scalable Kubernetes delivery platform on AWS EKS for Mobilesentrix. I modernized Jenkins by moving to Kubernetes dynamic agents and Kaniko-based builds, which improved build elasticity and security isolation. I implemented multi-layer autoscaling using HPA/VPA and Karpenter with Spot-aware policies to reduce cost while maintaining performance. I also built observability and SLO-based alerting with Prometheus, Grafana, and CloudWatch, then iteratively tuned resource profiles and scaling policies using production telemetry. The result was faster deployments, better cluster stability, and lower infrastructure spend.”
