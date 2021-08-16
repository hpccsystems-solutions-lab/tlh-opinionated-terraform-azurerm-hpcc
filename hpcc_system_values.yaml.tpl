global:
  image:
    root: "hpccsystems"
    pullPolicy: IfNotPresent

  logging:
    detail: 80
  
  egress:
    restricted: true

  cost:
    moneyLocale: "en_US.UTF-8"
    perCpu: 0.126

  metrics:
    sinks:
      - type: log
        name: logging
        settings:
          period: 60

security:
  eclSecurity:
    embedded: "allow"
    pipe:  "allow"
    extern: "allow"
    datafile: "allow"

storage:
  planes:
%{~ for key, value in storage }
  - name: ${key}
%{~ if can(value.pvc_name) }
    pvc: ${value.pvc_name}
%{~ endif }
    prefix: "${path_prefix}/${value.path}"
    category: ${can(value.category) ? value.category : key}
%{ endfor ~}

certificates:
  enabled: false
  issuers:
    local:
      name: letsencrypt-issuer
      kind: ClusterIssuer
      spec: null
    public:
      name: letsencrypt-issuer
      kind: ClusterIssuer
      spec: null

secrets:
  storage: {}
  ecl: {}
  codeSign: {}
  codeVerify: {}
  system: {}

vaults:
  storage:
  ecl:
  ecl-user:
  esp:
  codeSign:
  codeVerify:

bundles: []

dali:
- name: mydali
  services:
    coalescer:
      service:
        servicePort: 8877

sasha:
  wu-archiver:
    service:
      servicePort: 8877
    plane: sasha

  dfuwu-archiver:
    service:
      servicePort: 8877
    plane: sasha

  dfurecovery-archiver:

  file-expiry:

dfuserver:
- name: dfuserver
  maxJobs: 1

eclagent:
- name: hthor
  replicas: 1
  maxActive: 4
  prefix: hthor
  useChildProcesses: false
  type: hthor

- name: roxie-workunit
  replicas: 1
  prefix: roxie_workunit
  maxActive: 20
  useChildProcesses: true
  type: roxie

eclccserver:
- name: myeclccserver
  replicas: 1
  useChildProcesses: false
  maxActive: 4
  listen: []
    
esp:
- name: eclwatch
  application: eclwatch
  auth: none
  replicas: 1
  service:
    port: 8888
    servicePort: 8010
    visibility: local

- name: eclservices
  application: eclservices
  auth: none
  replicas: 1
  service:
    servicePort: 8010
    visibility: cluster

- name: eclqueries
  application: eclqueries
  auth: none
  replicas: 1
  service:
    servicePort: 8002
    visibility: local

- name: esdl-sandbox
  application: esdl-sandbox
  auth: none
  replicas: 1
  service:
    servicePort: 8899
    visibility: local

- name: sql2ecl
  application: sql2ecl
  auth: none
  replicas: 1
  service:
    servicePort: 8510
    visibility: local

roxie:
- name: roxie
  disabled: false
  prefix: roxie
  services:
  - name: roxie
    servicePort: 9876
    listenQueue: 200
    numThreads: 30
    visibility: local
  replicas: 2  
  numChannels: 2
  serverReplicas: 0
  localAgent: false
  useAeron: false
  topoServer:
    replicas: 1
    #traceLevel: 1

thor:
- name: thor
  prefix: thor
  numWorkers: 2
  maxJobs: 4
  maxGraphs: 2

eclscheduler:
- name: eclscheduler