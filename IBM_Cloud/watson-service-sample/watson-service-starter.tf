

variable "org" {
  type                        = "string"
  description                 = "Your Bluemix ORG"
}

variable "space" {
  type                        = "string"
  description                 = "Your Bluemix Space"
}

variable "servicename" {
/*
"options": [
  {
    "value": "APIConnect",
    "label": "Create, manage, enforce, and run APIs."
  },
  {
    "value": "AT&T Flow Designer",
    "label": "Design, Build and Deploy IoT Solutions in Minutes"
  },
  {
    "value": "AT&T IoT Data Plans",
    "label": "Launch your IoT product fast with IoT data plans"
  },
  {
    "value": "Accern-API",
    "label": "Get the most advanced breaking news technology for your investment strategies."
  },
  {
    "value": "AppConnect",
    "label": "Connect your applications, automate tasks, and improve productivity"
  },
  {
    "value": "AppID",
    "label": "Add authentication to your apps, and host user profile information so you can build engaging experiences."
  },
  {
    "value": "AppLaunch",
    "label": "Accelerate the delivery of innovations to mobile apps by avoiding release cycle complexities."
  },
  {
    "value": "Auto-Scaling",
    "label": "Automatically increase or decrease the number of application instances based on a policy you define."
  },
  {
    "value": "AvailabilityMonitoring",
    "label": "Around the world, around the clock availability and performance monitoring."
  },
  {
    "value": "BigInsightsForApacheHadoop",
    "label": "Provision managed Apache Hadoop and Spark clusters within minutes."
  },
  {
    "value": "BigInsightsonCloud",
    "label": "Provision managed bare metal Apache Hadoop clusters for production use or POCs at scale."
  },
  {
    "value": "Bondevalue-API",
    "label": "Real time bonds data to manage one’s bond investments."
  },
  {
    "value": "Car Diagnostic API",
    "label": "Translation service for OBD error codes."
  },
  {
    "value": "Continuous Release",
    "label": "Manage software deployments with this enterprise-scale release management solution."
  },
  {
    "value": "Contrast Security",
    "label": "Detect vulnerabilities and block attacks"
  },
  {
    "value": "DataWorks_Gen3",
    "label": "Data Connect: Self-service data preparation and integration for analytics projects."
  },
  {
    "value": "DevOpsInsights",
    "label": "Improve agility, reliability, and security by using machine learning and analytics"
  },
  {
    "value": "Document Generation",
    "label": "Generate documents from any standard data source with the Document Generation for Bluemix service."
  },
  {
    "value": "Esri ArcGIS for Developers",
    "label": "Bring the power of location to your apps with ArcGIS."
  },
  {
    "value": "GEO Web Services",
    "label": "Adding geo-intelligence to your business."
  },
  {
    "value": "Geospatial Analytics",
    "label": "Expand the boundaries of your application. Leverage real-time geospatial analytics to track when devices enter, leave or hang out in defined regions."
  },
  {
    "value": "IBMAnalyticsEngine",
    "label": "Flexible framework to deploy Hadoop and Spark analytics applications."
  },
  {
    "value": "IBM_Cloud_Brokerage_CAM",
    "label": "Hybrid Cloud Cost and Asset management service broker"
  },
  {
    "value": "InfluxCloud",
    "label": "A modern time series data platform for metrics & events"
  },
  {
    "value": "Integration Testing",
    "label": "Automated Integration Testing for Bluemix"
  },
  {
    "value": "Intelligent Travel API",
    "label": "ZUMATA's Artificial Intelligence for personalized hotel search experience."
  },
  {
    "value": "Internet of Things Workbench",
    "label": "An intuitive development environment for rapid design, simulation, & construction of complete Internet of Things solutions and services"
  },
  {
    "value": "Lift",
    "label": "Lift is a fully managed data migration service."
  },
  {
    "value": "Mapbox Maps",
    "label": "Add powerful custom maps to your app"
  },
  {
    "value": "Mobile Foundation",
    "label": "Comprehensive Mobile Backend for your digital apps"
  },
  {
    "value": "Monitoring",
    "label": "Collect, store, and analyze metrics from your dynamic cloud environments and micro-service applications."
  },
  {
    "value": "MonitoringAndAnalytics",
    "label": "Gain the visibility and control you need over your application. Determine the response time your users see, understand the performance and availability of the application components, leverage analytics to keep your application up and performing well, and get automatically notified if application problems occur."
  },
  {
    "value": "Natural Language Generation APIs",
    "label": "Generate expertly written narratives in seconds"
  },
  {
    "value": "Nexmo",
    "label": "Build great communication experiences."
  },
  {
    "value": "Object-Storage",
    "label": "Provides a cost-effective, scalable, unstructured cloud data store to build and deliver cloud apps and services."
  },
  {
    "value": "PagerDuty",
    "label": "Incident Management and Resolution Platform"
  },
  {
    "value": "Passport",
    "label": "Modern Identity and User Management"
  },
  {
    "value": "Payeezy",
    "label": "Simple, powerful payments"
  },
  {
    "value": "Plaid",
    "label": "Innovate in financial services."
  },
  {
    "value": "Precision Location",
    "label": "Skyhook Precision Location"
  },
  {
    "value": "Quovo",
    "label": "Connecting You to Your Users' Financial Accounts"
  },
  {
    "value": "RiskSpan RS Edge Loan Analytics",
    "label": "A loan analytics and predictive modeling platform"
  },
  {
    "value": "Rocket Mainframe Data",
    "label": "Rocket Mainframe Data Service on Bluemix provides an easy way to leverage your mainframe data for new cloud services and mobile apps. Built on our proven data virtualization technology, this new mainframe data provides access to a breadth of data sources--without worrying about the underlying data format. Developers have the flexibility to use either MongoDB or SQL (JDBC) to access data on z Systems. With Rocket Mainframe Data Service on Bluemix, developers working in IBM Bluemix now have an agile method for incorporating system of record data on z Systems into cloud or mobile applications."
  },
  {
    "value": "SecureGateway",
    "label": "IBM Secure Gateway for Bluemix enables users to integrate cloud services with enterprise systems on premises."
  },
  {
    "value": "SingleSignOn",
    "label": "Implement user authentication for your web and mobile apps quickly, using simple policy-based configurations."
  },
  {
    "value": "Twilio",
    "label": "Build apps that communicate. Integrate voice, messaging and VoIP into your web and mobile apps."
  },
  {
    "value": "UnificationEngine",
    "label": "Intelligent IoT messaging for all H2M communications."
  },
  {
    "value": "VoiceAgent",
    "label": "Create a cognitive voice agent that uses Watson services to speak directly with customers using natural language over the telephone"
  },
  {
    "value": "WealthEngine API",
    "label": "Look up anyone's net worth in real-time."
  },
  {
    "value": "WebSphereAppSvr",
    "label": "Allows you to quickly get up and running on a pre-configured WebSphere Application Server installation in a hosted cloud environment on Bluemix."
  },
  {
    "value": "WorkloadScheduler",
    "label": "Automate your tasks to run one time or on recurring schedules. Far beyond Cron, exploit job scheduling within and outside Bluemix."
  },
  {
    "value": "XPagesData",
    "label": "Create an IBM Notes .NSF database to store your XPages Domino data."
  },
  {
    "value": "Xignite Market Data APIs",
    "label": "Real-time and reference market data"
  },
  {
    "value": "Ylabs",
    "label": "Full banking stack with enhanced KYC and real time risk monitoring."
  },
  {
    "value": "Zuznow",
    "label": "Automatically develop mobile apps"
  },
  {
    "value": "accessTrail",
    "label": "Capture, store, and visualize your Bluemix cloud activities"
  },
  {
    "value": "alertnotification",
    "label": "Never miss critical alerts. Notify the right people immediately. Speed up response with automated escalation policies."
  },
  {
    "value": "apersona-amfa",
    "label": "Frictionless Adaptive Multi-Factor Authentication"
  },
  {
    "value": "apiHarmony",
    "label": "IBM API Harmony for Bluemix supports developers in identifying and selecting APIs."
  },
  {
    "value": "apprenda",
    "label": "Bluemix .NET Powered by Apprenda"
  },
  {
    "value": "attm2x",
    "label": "Time Series IoT Data Service"
  },
  {
    "value": "blazemeter",
    "label": "Performance Testing Platform"
  },
  {
    "value": "box",
    "label": "Powering Content and data for your application."
  },
  {
    "value": "businessrules",
    "label": "Automate and manage business logic in applications using business rules."
  },
  {
    "value": "cleardb",
    "label": "Highly available MySQL for Apps."
  },
  {
    "value": "cloud-object-storage",
    "label": "Provides flexible, cost-effective, and scalable cloud storage for unstructured data."
  },
  {
    "value": "cloudamqp",
    "label": "Managed HA RabbitMQ servers in the cloud"
  },
  {
    "value": "cloudantNoSQLDB",
    "label": "Cloudant NoSQL DB is a fully managed data layer designed for modern web and mobile applications that leverages a flexible JSON schema. Cloudant is built upon and compatible with Apache CouchDB and accessible through a secure HTTPS API, which scales as your application grows. Cloudant is ISO27001 and SOC2 Type 1 certified, and all data is stored in triplicate across separate physical nodes in a cluster for HA/DR within a data center."
  },
  {
    "value": "cloudautomationmanager",
    "label": "Provision cloud infrastructure and applications in multiple cloud providers."
  },
  {
    "value": "cloudeventmanagement",
    "label": "Consolidated operational event and incident management."
  },
  {
    "value": "compose-enterprise",
    "label": "IBM Compose Enterprise is a service which provides a private isolated cluster for Bluemix users to optionally provision their Compose databases into."
  },
  {
    "value": "compose-for-elasticsearch",
    "label": "Elasticsearch combines the power of a full text search engine with the indexing strengths of a JSON document database to create a powerful tool for rich data analysis on large volumes of data. With Elasticsearch your searching can be scored for exactness letting you dig through your data set for those close matches and near misses which you could be missing. IBM Compose for Elasticsearch makes Elasticsearch even better by managing it for you. This includes offering an easy, auto-scaling deployment system which delivers high availability and redundancy, automated no-stop backups and much more. Note: Compose via Bluemix does not give access to the Compose UI at this time, see https://help.compose.com/docs/bluemix-compose-support for more details."
  },
  {
    "value": "compose-for-etcd",
    "label": "etcd is a key/value store developers can use to hold the always-correct data you need to coordinate and manage your server cluster for distributed server configuration management. etcd uses the RAFT consensus algorithm to assure data consistency in your cluster and also enforces the order in which operations take place in the data so that every node in the cluster arrives at the same result in the same way. IBM Compose for etcd makes etcd even better by managing it for you. This includes offering an easy, auto-scaling deployment system which delivers high availability and redundancy, automated no-stop backups and much more. Note: Compose via Bluemix does not give access to the Compose UI at this time, see https://help.compose.com/docs/bluemix-compose-support for more details."
  },
  {
    "value": "compose-for-janusgraph",
    "label": "JanusGraph is a scalable graph database optimized for storing and querying highly-interconnected data modeled as millions or billions of vertices and edges. Simple and efficient retrieval of data from these complex structures is enabled by JanusGraph’s Apache TinkerPop(TM) compatibility allowing users to perform efficient queries that would be difficult or impossible with a traditional RDBMS. IBM Compose for JanusGraph makes JanusGraph even better by managing it for you. This includes offering an easy, auto-scaling deployment system which delivers high availability and redundancy, automated no-stop backups and much more."
  },
  {
    "value": "compose-for-mongodb",
    "label": "MongoDB with its powerful indexing and querying, aggregation and wide driver support, has become the go-to JSON data store for many startups and enterprises. IBM Compose for MongoDB makes MongoDB even better by managing it for you. This includes offering an easy, auto-scaling deployment system which delivers high availability and redundancy, automated no-stop backups and much more. Note: Compose via Bluemix does not give access to the Compose UI at this time, see https://help.compose.com/docs/bluemix-compose-support for more details."
  },
  {
    "value": "compose-for-mysql",
    "label": "MySQL is probably the most popular open source relational database in the world; it debuted in 1995 and rapidly became an essential part of the internet's infrastructure as a component of the LAMP stack. Since then it has been constantly evolving under different owners. With a broad subset of ANSI SQL 99 and a wide set of its own extensions, including JSON document, full text search and updatable views, MySQL offers a rich palette for developers to draw on in their applications. Administrators will also find a wide selection of database management tools that can work with MySQL. IBM Compose for MySQL makes MySQL even better by managing it for you. This includes offering an easy, auto-scaling deployment system which delivers high availability and redundancy, automated no-stop backups and much more. Note: Compose via Bluemix does not give access to the Compose UI at this time, see https://help.compose.com/docs/bluemix-compose-support for more details."
  },
  {
    "value": "compose-for-postgresql",
    "label": "Postgres is a powerful, open source object-relational database that is highly customizable. With Postgres, development is fast and easily scalable, plus you can develop in a language you're comfortable with like C/C++, Perl, Python, TCL/TK, Delphi/Kylix, VB, PHP, ASP, and Java just for starters. It's a feature-rich enterprise database with JSON support, giving you the best of both the SQL and NoSQL worlds. IBM Compose for PostgreSQL makes Postgres even better by managing it for you. This includes offering an easy, auto-scaling deployment system which delivers high availability and redundancy, automated no-stop backups and much more. Note: Compose via Bluemix does not give access to the Compose UI at this time, see https://help.compose.com/docs/bluemix-compose-support for more details."
  },
  {
    "value": "compose-for-rabbitmq",
    "label": "RabbitMQ asynchronously handles the messages between your applications and databases, allowing you to ensure separation of the data and application layers. RabbitMQ lets you route, track, and queue messages with customizable persistence levels, delivery settings, and publish confirmations. IBM Compose for RabbitMQ makes RabbitMQ even better by managing it for you. This includes offering an easy, auto-scaling deployment system which delivers high availability and redundancy, automated no-stop backups and much more. Note: Compose via Bluemix does not give access to the Compose UI at this time, see https://help.compose.com/docs/bluemix-compose-support for more details."
  },
  {
    "value": "compose-for-redis",
    "label": "Redis is an open-source, blazingly fast, key/value low maintenance store. Compose's platform gives you a configuration pre-tuned for high availability and locked down with additional security features. IBM Compose for Redis makes Redis even better by managing it for you. This includes offering an easy, auto-scaling deployment system which delivers high availability and redundancy, automated no-stop backups and much more. Note: Compose via Bluemix does not give access to the Compose UI at this time, see https://help.compose.com/docs/bluemix-compose-support for more details."
  },
  {
    "value": "compose-for-rethinkdb",
    "label": "RethinkDB is a JSON document based, distributed database with an integrated administration and exploration console. RethinkDB uses the ReQL query language which is built around function chaining and is available in client libraries for JavaScript, Python and Ruby. With ReQL it is possible to utilize RethinkDB server side features such as distributed joins and subqueries across the cluster’s nodes. RethinkDB also supports secondary indexes for better read query performance and the developers have just added geospatial indexes and queries. IBM Compose for RethinkDB makes RethinkDB even better by managing it for you. This includes offering an easy, auto-scaling deployment system which delivers high availability and redundancy, automated no-stop backups and much more. Note: Compose via Bluemix does not give access to the Compose UI at this time, see https://help.compose.com/docs/bluemix-compose-support for more details."
  },
  {
    "value": "compose-for-scylladb",
    "label": "ScyllaDB is a highly performant, in-place replacement for the Cassandra wide-column distributed database. ScyllaDB is written in C++, rather than Cassandra's Java, for better resource usage that can result in ten times better performance in benchmarks. Whilst retaining compatibility with Cassandra tool and data files, ScyllaDB adds self tuning capabilities. IBM Compose for ScyllaDB makes ScyllaDB even better by managing it for you. This includes offering an easy, auto-scaling deployment system which delivers high availability and redundancy, automated no-stop backups and much more. Note: Compose via Bluemix does not give access to the Compose UI at this time, see https://help.compose.com/docs/bluemix-compose-support for more details."
  },
  {
    "value": "continuous-delivery",
    "label": "Build, test and deliver using DevOps best practices."
  },
  {
    "value": "conversation",
    "label": "Add a natural language interface to your application to automate interactions with your end users. Common applications include virtual agents and chat bots that can integrate and communicate on any channel or device."
  },
  {
    "value": "cpy-insights",
    "label": "Business Activity Insights for Bluemix© apps"
  },
  {
    "value": "dashDB",
    "label": "A flexible and powerful data warehouse for enterprise-level analytics."
  },
  {
    "value": "dashDB For Transactions",
    "label": "A next generation SQL database. Formerly dashDB For Transactions."
  },
  {
    "value": "data-science-experience",
    "label": "Manage and analyze data, run notebooks, and collaborate on data science projects."
  },
  {
    "value": "datacatalog-broker-ypprod",
    "label": "Discover, catalog, and securely share enterprise data."
  },
  {
    "value": "datarefinery_service_ypprod",
    "label": "Self-service data preparation and integration for analytics projects."
  },
  {
    "value": "db2oncloud",
    "label": "Db2 Hosted: Offers customers the rich features of an on-premise Db2 deployment without the cost, complexity, and risk of managing their own infrastructure."
  },
  {
    "value": "discovery",
    "label": "Add a cognitive search and content analytics engine to applications."
  },
  {
    "value": "docplexcloud",
    "label": "Develop optimization applications, such as planning or scheduling, using our APIs to connect to the CPLEX optimization engines."
  },
  {
    "value": "dreamface",
    "label": "Cloud Application Development Platform"
  },
  {
    "value": "driverinsights",
    "label": "IBM Watson IoT Driver Behavior Service lets you analyze drivers' behavior from vehicle probe data and contextual data."
  },
  {
    "value": "dsoncloud",
    "label": "IBM® Information Server on Cloud allows you to rapidly expand data integration and governance capabilities into the cloud for new or ad hoc development and testing environments."
  },
  {
    "value": "ecs-checker",
    "label": "Automate accessibility verification of HTML and EPUB documents."
  },
  {
    "value": "ecs-dashboard",
    "label": "Integrate automated accessibility auditing and reporting capabilities into your deployment DevOps processes."
  },
  {
    "value": "elephantsql",
    "label": "PostgreSQL as a Service"
  },
  {
    "value": "fss-financial-optimization-service",
    "label": "Construct or rebalance investment portfolios based on investor goals, mandates, and preferences."
  },
  {
    "value": "fss-historical-instrument-analytics-service",
    "label": "Leverage sophisticated IBM Algorithmics financial models to price and evaluate financial securities for historical dates."
  },
  {
    "value": "fss-historical-scenario-analytics-service",
    "label": "Leverage sophisticated IBM Algorithmics financial models to price and compute analytics on financial securities for a historical date, under a scenario."
  },
  {
    "value": "fss-instrument-analytics-service",
    "label": "Leverage sophisticated IBM Algorithmics financial models to price and compute analytics on financial securities."
  },
  {
    "value": "fss-portfolio-service",
    "label": "Maintain a record of your investment portfolios through time."
  },
  {
    "value": "fss-predictive-scenario-analytics-service",
    "label": "Create conditional scenarios to model how, given a change to a subset of factors the broader set of market factors are expected to change."
  },
  {
    "value": "fss-scenario-analytics-service",
    "label": "Leverage sophisticated IBM Algorithmics financial models to price and compute analytics on financial securities under a given scenario."
  },
  {
    "value": "g11n-pipeline",
    "label": "Manage the translation of your cloud and mobile applications using IBM Globalization Pipeline."
  },
  {
    "value": "hiptest",
    "label": "The most simple and powerful test management platform"
  },
  {
    "value": "ibm-blockchain-5-prod",
    "label": "Utilize IBM's Blockchain Technology within Bluemix"
  },
  {
    "value": "ibm-iot-for-electronics",
    "label": "The IoT for Electronics service supports user and device registration and notifications. As part of the IoT for Electronics Starter, it is preconfigured with other services to help you connect your devices and get your IoT projects to market significantly faster. You can also deploy it separately and use it with an existing instance of IBM® Watson™ IoT Platform."
  },
  {
    "value": "ibmLogAnalysis",
    "label": "Collect, store, and analyze your application's log data."
  },
  {
    "value": "imfpush",
    "label": "Scalable and reliable Push Notifications service for mobile and web applications"
  },
  {
    "value": "informix_on_cloud",
    "label": "IBM Informix on Cloud helps businesses gain a trusted view of data in a hybrid computing environment."
  },
  {
    "value": "iot-for-insurance",
    "label": "IBM© IoT for Insurance is an integrated IoT production instance that collects and analyzes full-context data from policy holders to provide personalized risk assessment, real-time protection, and policy cost reductions."
  },
  {
    "value": "iotf-service",
    "label": "This service is the hub of all things IBM IoT, it is where you can set up and manage your connected devices so that your apps can access their live and historical data."
  },
  {
    "value": "iotforautomotive",
    "label": "IoT for Automotive provides automotive domain specialized application development enablers for data acquisition, storage, real-time processing, and business rules support."
  },
  {
    "value": "iqpiot",
    "label": "Code-Free IoT App Creation"
  },
  {
    "value": "jkoolapi",
    "label": "jKool provides real-time and historical visualization and analytics"
  },
  {
    "value": "kinetise",
    "label": "Rapid development of mobile apps. With Native Source Code."
  },
  {
    "value": "kms",
    "label": "An app-independent service for protecting, managing, and generating keys."
  },
  {
    "value": "knowledge-studio",
    "label": "Build custom models to teach Watson the language of your domain."
  },
  {
    "value": "language_translator",
    "label": "Translate text from one language to another for specific domains."
  },
  {
    "value": "loadimpact",
    "label": "Performance and load testing for DevOps"
  },
  {
    "value": "mapinsights",
    "label": "IBM Watson IoT Context Mapping Service brings the power to your application to analyze moving object trajectories by leveraging road network-based geospatial services."
  },
  {
    "value": "mdmoncloud",
    "label": "IBM® Master Data Management (MDM) on Cloud helps businesses gain a trusted view of data in a hybrid computing environment."
  },
  {
    "value": "memcachedcloud",
    "label": "Enterprise-Class Memcached for Developers"
  },
  {
    "value": "messagehub",
    "label": "IBM Message Hub is a scalable, distributed, high throughput message bus to unite your on-premise and off-premise cloud technologies."
  },
  {
    "value": "mobile-analytics_Prod",
    "label": "Mobile app developers and business stakeholders: Use IBM Mobile Analytics for Bluemix to gain insight into how your app is performing and how it is being used."
  },
  {
    "value": "mongodb-replaced",
    "label": "This service is no longer available. Please search for Compose services in the main catalog instead."
  },
  {
    "value": "moni-ai",
    "label": "Virtual Assistant for the IoT"
  },
  {
    "value": "mysql-replaced",
    "label": "This service is no longer available. Please search for Compose services in the main catalog instead."
  },
  {
    "value": "namara-catalog",
    "label": "Open Data. Clean and simple."
  },
  {
    "value": "natural-language-understanding",
    "label": "Analyze text to extract meta-data from content such as concepts, entities, emotion, relations, sentiment and more."
  },
  {
    "value": "natural_language_classifier",
    "label": "Natural Language Classifier performs natural language classification on question texts. A user would be able to train their data and the predict the appropriate class for a input question."
  },
  {
    "value": "newrelic",
    "label": "Manage and monitor your apps"
  },
  {
    "value": "personality_insights",
    "label": "The Watson Personality Insights derives insights from transactional and social media data to identify psychological traits"
  },
  {
    "value": "pitneybowes-apis",
    "label": "Add enterprise-class geodata and commerce technology your application"
  },
  {
    "value": "pm-20",
    "label": "IBM Watson Machine Learning - make smarter decisions, solve tough problems, and improve user outcomes."
  },
  {
    "value": "postgresql-replaced",
    "label": "This service is no longer available. Please search for Compose services in the main catalog instead."
  },
  {
    "value": "product_insights",
    "label": "Connect IBM products to track inventory and understand usage"
  },
  {
    "value": "pubnub-sandbox",
    "label": "Data Streaming and Realtime Communication"
  },
  {
    "value": "push-reappt",
    "label": "Real Time Data Distribution Service"
  },
  {
    "value": "rabbitmq-replaced",
    "label": "This service is no longer available. Please search for Compose services in the main catalog instead."
  },
  {
    "value": "redis-replaced",
    "label": "This service is no longer available. Please search for Compose services in the main catalog instead."
  },
  {
    "value": "rediscloud",
    "label": "Enterprise-Class Redis for Developers"
  },
  {
    "value": "runbookautomation",
    "label": "Support Operators by providing a structured way of executing Runbooks."
  },
  {
    "value": "schematics",
    "label": "IBM Cloud Schematics"
  },
  {
    "value": "searchly",
    "label": "Search Made Simple. Powered-by Elasticsearch"
  },
  {
    "value": "sendgrid",
    "label": "Delivering your email through one reliable platform."
  },
  {
    "value": "simplicite",
    "label": "Versatile Cloud Platform for Enterprise Applications"
  },
  {
    "value": "spark",
    "label": "IBM Analytics for Apache Spark for Bluemix."
  },
  {
    "value": "speech_to_text",
    "label": "Low-latency, streaming transcription"
  },
  {
    "value": "statica",
    "label": "Enterprise Static IP Addresses"
  },
  {
    "value": "streaming-analytics",
    "label": "Ingest, analyze, monitor, and correlate data as it arrives from real-time data sources. View information and events as they unfold."
  },
  {
    "value": "testdroid",
    "label": "Mobile testing cloud service"
  },
  {
    "value": "text_to_speech",
    "label": "Synthesizes natural-sounding speech from text."
  },
  {
    "value": "tinyqueries",
    "label": "Create complex queries easily"
  },
  {
    "value": "tone_analyzer",
    "label": "Tone Analyzer uses linguistic analysis to detect three types of tones from communications: emotion, social, and language."
  },
  {
    "value": "ustream",
    "label": "Video streaming, storage and publishing."
  },
  {
    "value": "vantrix-transcoder",
    "label": "Video Transcoding"
  },
  {
    "value": "watson_vision_combined",
    "label": "Find meaning in visual content! Analyze images for scenes, objects, faces, and other content. Choose a default model off the shelf, or create your own custom classifier. Develop smart applications that analyze the visual content of images or video frames to understand what is happening in a scene."
  },
  {
    "value": "watsoncontent",
    "label": "Watson Knowledge Kits are pre-trained data from different industries and for your cognitive apps offered as APIs"
  },
  {
    "value": "weatherinsights",
    "label": "Use the Weather Company Data for IBM Bluemix service to incorporate weather data into your Bluemix applications."
  },
  {
    "value": "xpertrule-node-red",
    "label": "Decision Author for node-RED"
  },
  {
    "value": "xpertrule-nodejs",
    "label": "Non-coders and developers can automate and execute business decisions"
  }
]
*/
  type                        = "string"
  description                 = "Specify the service name you want to create"
}

variable "plan" {
  type                        = "string"
  description                 = "Specify the corresponding plan for the service you selected"
}

variable "region" {
  type                        = "string"
  description                 = "Bluemix region"
  default                     = "eu-gb"
}
################################################
# This module creates a free 1-node kubernetes cluster
# that will be the home of the web shop.
################################################

################################################
# Load org data
################################################
data "ibm_org" "orgData" {
  org                         = "${var.org}"
}

################################################
# Load space data
################################################
data "ibm_space" "spaceData" {
  space                       = "${var.space}"
  org                         = "${data.ibm_org.orgData.org}"
}

################################################
# Load account data
################################################
data "ibm_account" "accountData" {
  org_guid                    = "${data.ibm_org.orgData.id}"
}

################################################
# Create cloudant instance
################################################
resource "ibm_service_instance" "service" {
  name                        = "${var.servicename}-${random_pet.service.id}"
  space_guid                  = "${data.ibm_space.spaceData.id}"
  service                     = "${var.servicename}"
  plan                        = "${var.plan}"
}

################################################
# Generate access info
################################################
resource "ibm_service_key" "serviceKey" {
  name                        = "${var.servicename}-${random_pet.service.id}"
  service_instance_guid       = "${ibm_service_instance.service.id}"
}

################################################
# Generate a name
################################################
resource "random_pet" "service" {
  length                      = "2"
}
# Configure the IBM Cloud Provider
provider "ibm" {
  # bluemix_api_key             = "${var.ibm_bmx_api_key}"
  region                      = "${var.region}"
  version = "~> 0.5" 
}

################################################
# outputs
################################################
output "service_credentials" {
  value = "${ibm_service_key.serviceKey.credentials}"
}

output "ibm_cloud_dashboard" {
  value = "https://console.bluemix.net/dashboard/apps/?search=visual"
}
