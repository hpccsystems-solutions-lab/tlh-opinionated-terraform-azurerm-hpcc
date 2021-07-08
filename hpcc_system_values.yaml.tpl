# Default values for hpcc.

global:
  # Settings in the global section apply to all HPCC components in all subcharts

  image:
    ## It is recommended to name a specific version rather than latest, for any non-trivial deployment
    ## For best results, the helm chart version and platform version should match. Leave this unset to use the
    ## version that matches the version of the helm chart
    #version: x.y.z 
    root: "hpccsystems"    # change this if you want to pull your images from somewhere other than DockerHub hpccsystems
    pullPolicy: IfNotPresent

  # logging sets the default logging information for all components. Can be overridden locally
  logging:
    detail: 80

  # Specify a defaultEsp to control which eclservices service is returned from Std.File.GetEspURL, and other uses
  # If not specified, the first esp component that exposes eclservices application is assumed.
  # Can also be overridden locally in individual components
  ## defaultEsp: eclservices
  
  egress:
    ## If restricted is set, NetworkPolicies will include egress restrictions to allow connections from pods only to the minimum required by the system
    ## Set to false to disable all egress policy restrictions (not recommended)
    restricted: true
    
    ## The kube-system namespace is not generally labelled by default - to enable more restrictive egress control for dns lookups we need to be told the label
    ## If not provided, DNS lookups on port 53 will be allowed to connect anywhere
    ## The namespace may be labelled using a command such as "kubectl label namespace kube-system name=kube-system"
    # kubeSystemLabel: "kube-system"

    ## To properly allow access to the kubectl API from pods that need it, the cidr of the kubectl endpoint needs to be supplied
    ## This may be obtained via "kubectl get endpoints --namespace default kubernetes"
    ## If these are not supplied, egress controls will allow access to any IPs/ports from any pod where API access is needed
    # kubeApiCidr: 172.17.0.3/32  
    # kubeApiPort: 7443

  cost:
    moneyLocale: "en_US.UTF-8"
    perCpu: 0.126

  # postJobCommand will execute at the end of a dynamically lauched K8s job,
  # when the main entrypoint process finishes, or if the readiness probes trigger a preStop event.
  # This can be useful if injected sidecars are installed that need to be told to stop.
  # If they are not stopped, the pod continues running with the side car container only, in a "NotReady" state.
  # An example of this is the Istio envoy side car. It can be stopped with the command below.
  # Set postJobCommandViaSidecar to true, if the command needs to run with priviledge, this will enable the command
  # to run as root in a sidecar in same process space as other containers, allowing it to for example send signals
  # to processes in sidecars

  # Define global default metrics configuration for all components
  metrics:
    sinks:
      - type: log
        name: logging
        settings:
          period: 60



  # For pod placement instruction and examples please reference docs/placements.md

security:
  eclSecurity:
    # Possible values:
    # allow - functionality is permitted
    # deny - functionality is not permitted
    # allowSigned - functionality permitted only if code signed
    embedded: "allow"
    pipe:  "allow"
    extern: "allow"
    datafile: "allow"

## storage:
##
## If storage.[type].existingClaim is defined, a Persistent Volume Claim must
## exist with that name. If an existingClaim is specified, storageClass and
## storageSize are not used.
##
## If storage.[type].storageClass is defined, storageClassName: <storageClass>
## If set to "-", storageClassName: "", which disables dynamic provisioning
## If undefined (the default) or set to null, no storageClassName spec is
##   set, choosing the default provisioner.  (gp2 on AWS, standard on
##   GKE, AWS & OpenStack)
##
## storage.[type].forcePermissions=true is required by some types of provisioned
## storage, where the mounted filing system has insufficient permissions to be
## read by the hpcc pods. Examples include using hostpath storage (e.g. on
## minikube and docker for desktop), or using NFS mounted storage.

storage:
  planes:
    %{ for key, value in storage}
  - name: ${key}
    pvc: "${value.pvc_name}"
    prefix: "${value.path_prefix}"
    labels: [ "${key}" ]
  %{ endfor}
  - name: mydropzone
    prefix: "/var/lib/HPCCSystems/dropzone"
    labels: [ "lz" ]

  dllStorage:
    plane: dll
    # existingClaim: ""
    # forcePermissions: false

  daliStorage:
    plane: dali
    # existingClaim: ""
    # forcePermissions: false

  dataStorage:
    plane: data
    # existingClaim: ""
    # forcePermissions: false

## The certificates section can be used to enable cert-manager to generate TLS certificates for each component in the hpcc.
## You must first install cert-manager to use this feature.
## https://cert-manager.io/docs/installation/kubernetes/#installing-with-helm
##
## The Certificate issuers are divided into "local" (those which will be used for local mutual TLS) and "public" those
## which will be publicly accesible and therefore need to be recognized by browsers and/or other entities.
##
## Both public and local issuers have a spec section. The contents of the "spec" are documented in the cer-manager
## "Issuer configuration" documentation. https://cert-manager.io/docs/configuration/#supported-issuer-types
##
## The default configuration is meant to provide reasonable functionality without additional dependencies.
##
## Public issuers can be tricky if you want browsers to recognize the certificates.  This is a complex topic outside the scope
## of this comment.  The default for the public issuer generates self signed certifiecates. The expectation is that this will be
## overriden by the configuration of an external certificate authority or vault in QA and production environments.
##
## The default for the local (mTLS) issuer is designed to act as our own local certificate authority. We need only need to recognize
## what a component is, and that it belongs to this cluster.
## But a kubernetes secret must be provided for the certificate authority key-pair.  The default name for the secret
## is "local-issuer-ca-key-pair". The secret is a standard kubernetes.io/tls secret and should provide data values for
## "tls.crt" and "tls.key".
##
## The local issuer can also be configured to use an external certificate authority or vault.
##
certificates:
  enabled: false
  issuers:
    local:
      name: hpcc-local-issuer
      ## kind can be changed to ClusterIssue to refer to a ClusterIssuer. https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.ClusterIssuer
      kind: Issuer
      ## do not define spec (set spec: null), to reference an Issuer resource that already exists in the cluster
      ## change spec if you'd like to change how certificates get issued... see ## https://cert-manager.io/docs/configuration/#supported-issuer-types
      ## for information on what spec should contain.
      spec:
        ca:
          secretName: hpcc-local-issuer-key-pair
    public:
      name: hpcc-public-issuer
      ## kind can be changed to ClusterIssue to refer to a ClusterIssuer. https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.ClusterIssuer
      kind: Issuer
      ## do not define spec (set spec: null), to reference an Issuer resource that already exists in the cluster
      ## change spec if you'd like to change how certificates get issued... see ## https://cert-manager.io/docs/configuration/#supported-issuer-types
      ## for information on what spec should contain.
      spec:
        selfSigned: {}

## The secrets section contains a set of categories, each of which contain a list of secrets.  The categories deterime which
## components have access to the secrets.
## For each secret:
##   name is the name that is is accessed by within the platform
##   secret is the name of the secret that should be published
secrets:
  #timeout: 300 # timeout period for cached secrets.  Should be similar to the k8s refresh period.

  #Secret categories follow, remove the {} if a secret is defined in a section
  storage: {}
    ## Secrets that are required for accessing storage.  Currently exposed in the engines, but in the future will
    ## likely be restricted to esp (when it becomes the meta-data provider)
    ## For example, to set the secret associated with the azure storage account "mystorageaccount" use
    ##azure-mystorageaccount: storage-myazuresecret

  ecl: {}
    ## Category for secrets published to all components that run ecl

  codeSign: {}
    #gpg-private-key-1: codesign-gpg-key-1
    #gpg-private-key-2: codesign-gpg-key-2

  codeVerify: {}
    #gpg-public-key-1: codesign-gpg-public-key-1
    #gpg-public-key-2: codesign-gpg-public-key-2

  system: {}
    ## Category for secrets published to all components for system level useage

## The vaults section mirrors the secret section but leverages vault for the storage of secrets.
## There is an additional category for vaults named "ecl-user".  In the future "ecl-user" vault
## secrets will be readable directly from ECL code.  Other secret categories are read internally
## by system components and not exposed directly to ECL code.
##
## For each vault:
##   name is the name that is is accessed by within the platform
##   url is the url used to read a secret from the vault.
##   kind is the type of vault being accessed, or the protocol to use to access the secrets
##   client_secret a kubernetes level secret that contains the client_token used to retrive secrets.
##       if a client_secret is not provided "vault kubernetes auth" will be attempted.

vaults:
  storage:

  ecl:

  ecl-user:
    #ECL code will have direct access to these secrets

  esp:

  ## The keys for code signing may be imported from the vault.  Multiple keys may be imported.
  ## gpg keys may be imported as follows:
  ## vault kv put secret/codeSign/gpg-private-key-1 passphrase=<passphrase> private=@<private_key_file1>
  ## vault kv put secret/codeSign/gpg-private-key-2 passphrase=<passphrase> private=@<private_key_file2>
  codeSign:
  ## The keys for verifying signed code may be imported from the vault.
  ## vault kv put secret/codeVerify/gpg-public-key-1 public=@<public_key_file1>
  ## vault kv put secret/codeVerify/gpg-public-key-2 public=@<public_key_file2>
  codeVerify:

bundles: []
## Specifying bundles here will cause the indicated bundles to be downloaded and installed automatically
## whenever an eclccserver pod is started
# for example
# - name: DataPatterns

dali:
- name: mydali
  services: # internal house keeping services
    coalescer:
      #servicePort: 8877
      #interval: 2 # (hours)
      #at: "* * * * *" # cron type schedule, i.e. Min(0-59) Hour(0-23) DayOfMonth(1-31) Month(1-12) DayOfWeek(0-6)
      #minDeltaSize: 50 # (Kb) will not start coalescing until delta log is above this threshold
      #resources:
      #  cpu: "1"
      #  memory: "1G"

  #metaAccess: "shared" # enable if coalescer running in separate pod, and thus needs access to meta over PVC mount

  #resources:
  #  cpu: "1"
  #  memory: "4G"

sasha:
  #disabled: true # disable all services. Alternatively set sasha to null (sasha: null)
  wu-archiver:
    #disabled: true
    servicePort: 8877
    storage:
      plane: sasha
      # forcePermissions: false
    #interval: 6 # (hours)
    #limit: 1000 # threshold number of workunits before archiving starts (0 disables)
    #cutoff: 8 # minimum workunit age to archive (days)
    #backup: 0 # minimum workunit age to backup (days, 0 disables)
    #at: "* * * * *"
    #duration: 0 # (maxDuration) - Maximum duration to run WorkUnit archiving session (hours, 0 unlimited)
    #throttle: 0 # throttle ratio (0-99, 0 no throttling, 50 is half speed)
    #retryinterval: 7 # minimal time before retrying archive of failed WorkUnits (days)
    #keepResultFiles: false # option to keep result files owned by workunits after workunit is archived

  dfuwu-archiver:
    #disabled: true
    servicePort: 8877
    storage:
      plane: sasha
      #forcePermissions: false
    #limit: 1000 # threshold number of DFU workunits before archiving starts (0 disables)
    #cutoff: 14 # minimum DFU workunit age to archive (days)
    #interval: 24 # minimum interval between running DFU recovery archiver (in hours, 0 disables)
    #at: "* * * * *" # schedule to run DFU workunit archiver (cron format)
    #duration: 0 # (maxDuration) maximum duration to run DFU WorkUnit archiving session (hours, 0 unlimited)
    #throttle: 0 # throttle ratio (0-99, 0 no throttling, 50 is half speed)

  dfurecovery-archiver:
    #disabled: true
    #limit: 20 # threshold number of DFU recovery items before archiving starts (0 disables)
    #cutoff: 4 # minimum DFU recovery item age to archive (days)
    #interval: 12 # minimum interval between running DFU recovery archiver(in hours, 0 disables)
    #at: "* * * * *" # schedule to run DFU recovery archiver (cron format)

  file-expiry:
    #disabled: true
    #interval: 1
    #at: "* 3 * * *"
    #persistExpiryDefault: 7
    #expiryDefault: 4
    #user: sasha

dfuserver:
- name: dfuserver
  maxJobs: 1

eclagent:
- name: hthor
  ## replicas indicates how many eclagent pods should be started
  replicas: 1
  ## maxActive controls how many workunits may be active at once (per replica)
  maxActive: 4
  ## prefix may be used to set a filename prefix applied to any relative filenames used by jobs submitted to this queue
  prefix: hthor
  ## Set to false if you want to launch each workunit in its own container, true to run as child processes in eclagent pod
  useChildProcesses: false
  ## type may be 'hthor' (the default) or 'roxie', to specify that the roxie engine rather than the hthor engine should be used for eclagent workunit processing
  type: hthor
  ## The following resources apply to child hThor pods when useChildProcesses=false, otherwise they apply to hThor pod.
  #resources:
  #  cpu: "1"
  #  memory: "1G"

- name: roxie-workunit
  replicas: 1
  prefix: roxie_workunit
  maxActive: 20
  useChildProcesses: true
  type: roxie
  #resources:
  #  cpu: "1"
  #  memory: "1G"

eclccserver:
- name: myeclccserver
  replicas: 1
  ## Set to false if you want to launch each workunit compile in its own container, true to run as child processes in eclccserver pod.
  useChildProcesses: false
  ## maxActive controls how many workunit compiles may be active at once (per replica)
  maxActive: 4
  ## Specify a list of queues to listen on if you don't want this eclccserver listening on all queues. If empty or missing, listens on all queues
  listen: []
  ## The following resources apply to child compile pods when useChildProcesses=false, otherwise they apply to eclccserver pod.
  #resources:
  #  cpu: "1"
  #  memory: "4G"
    
esp:
- name: eclwatch
  ## Pre-configured esp applications include eclwatch, eclservices, and eclqueries
  application: eclwatch
  auth: none
  replicas: 1
  ## port can be used to change the local port used by the pod. If omitted, the default port (8880) is used
  port: 8888
  ## servicePort controls the port that this service will be exposed on, either internally to the cluster, or externally
  servicePort: 8010
  ## Specify public: true if you want the service available from outside the cluster. Typically, eclwatch and wsecl are published externally, while eclservices is designed for internal use.
  public: true
  #resources:
  #  cpu: "1"
  #  memory: "2G"
- name: eclservices
  application: eclservices
  auth: none
  replicas: 1
  servicePort: 8010
  public: false
  #resources:
  #  cpu: "250m"
  #  memory: "1G"
- name: eclqueries
  application: eclqueries
  auth: none
  replicas: 1
  public: true
  servicePort: 8002
  #resources:
  #  cpu: "250m"
  #  memory: "1G"
- name: esdl-sandbox
  application: esdl-sandbox
  auth: none
  replicas: 1
  public: true
  servicePort: 8899
  #resources:
  #  cpu: "250m"
  #  memory: "1G"
- name: sql2ecl
  application: sql2ecl
  auth: none
  replicas: 1
  public: true
  servicePort: 8510
  #domain: hpccsql.com
  #resources:
  #  cpu: "250m"
  #  memory: "1G"

roxie:
- name: roxie
  disabled: false
  prefix: roxie
  services:
  - name: roxie
    port: 9876
    listenQueue: 200
    numThreads: 30
    external: true
  ## replicas indicates the number of replicas per channel
  replicas: 2  
  numChannels: 2
  ## Set serverReplicas to indicate a separate replicaSet of roxie servers, with agent nodes not acting as servers
  serverReplicas: 0
  ## Set localAgent to true for a scalable cluster of "single-node" roxie servers, each implementing all channels locally
  localAgent: false
  useAeron: false
  ## Set mtuPayload to the maximum amount of data Roxie will put in a single packet. This should be just less than the system MTU. Default is 1400
  # mtuPayload: 3800
  #channelResources:
  #  cpu: "4"
  #  memory: "4G"
  #serverResources:
  #  cpu: "1"
  #  memory: "1G"
  topoServer:
    replicas: 1
    #traceLevel: 1

thor:
- name: thor
  prefix: thor
  numWorkers: 2
  maxJobs: 4
  maxGraphs: 2
  #managerResources:
  #  cpu: "1"
  #  memory: "2G"
  #workerResources:
  #  cpu: "4"
  #  memory: "4G"
  #eclAgentResources:
  #  cpu: "1"
  #  memory: "2G"

eclscheduler:
- name: eclscheduler

