```bash
for n in "grafana" "prometheus" "loki" "node_exporter" "promtail"; do ansible-galaxy init $n-deploy; done
```
