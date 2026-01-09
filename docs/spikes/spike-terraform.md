# Spike-onderzoek: Terraform als Infrastructure-as-Code oplossing

## Doel van de spike
Het doel van dit onderzoek is **begrijpen en evalueren** van Terraform, niet direct om een productieklare implementatie te bouwen. Ook zal worden vergeleken met alternatieve oplossingen.

## Hoofd- en deelvragen
"In hoeverre is Terraform geschikt om te gebruiken als orkestratie-tool binnen onze applicatie-architectuur, en welke voordelen of beperkingen brengt dit met zich mee in vergelijking met alternatieven zoals Kubernetes?"

### Deelvragen
- Wat doet Terraform precies op het gebied van orkestratie, en hoe onderscheidt het zich van traditionele infrastructuur-provisioning?
- Hoe kan Terraform worden geïntegreerd binnen onze bestaande ontwikkel- en deployprocessen, zoals CI/CD-pipelines en versiebeheer?
- Welke meerwaarde biedt Terraform op het gebied van orkestratie ten opzichte van Kubernetes, en in hoeverre vullen beide tools elkaar aan binnen een moderne applicatiearchitectuur?
- In hoeverre is het technisch haalbaar om met Terraform een werkende orkestratie op te zetten voor een voorbeeldapplicatie (bijv. met meerdere componenten zoals frontend, backend en database)?
- Wat zijn de voor- en nadelen van Terraform als orkestratie-tool binnen onze context, vergeleken met andere oplossingen zoals Ansible, Helm of Pulumi?
- Op basis van de bevindingen, is het aan te raden Terraform verder te implementeren of uit te breiden voor orkestratie binnen onze applicatie, of zijn alternatieven geschikter?

## Aanpak en criteria
### Onderzoeksaanpak
1. **Theoretische verkenning:**
	- Bestuderen van Terraform-documentatie, HashiCorp whitepapers en relevante literatuur.
	- Analyse van hoe Terraform zich verhoudt tot tools als Ansible, Pulumi, Helm en ArgoCD.
	- Bestuderen van integratiemogelijkheden met CI/CD en versiebeheer.
2. **Praktisch prototype:**
	- Opzetten van een eenvoudige "Hello World"-infrastructuur met Terraform.
	- Evaluatie van workflow en bruikbaarheid.
3. **Evaluatie:**
	- Beoordeling op basis van duidelijk gedefinieerde criteria.
	- Reflectie op toepasbaarheid binnen onze organisatie.

### Beoordelingscriteria
De volgende criteria zijn gebruikt om Terraform te evalueren:
- **Functionaliteit:** In hoeverre ondersteunt Terraform onze gewenste infrastructuurbehoeften?
- **Gebruiksgemak:** Hoe eenvoudig is de leercurve en het dagelijks gebruik?
- **Integratie:** Hoe goed past Terraform binnen bestaande CI/CD-processen en tooling?
- **Onderhoudbaarheid:** Hoe goed zijn configuraties te beheren, hergebruiken en uitbreiden?
- **Schaalbaarheid:** Hoe goed schaalt Terraform bij groeiende infrastructuren?
- **Vergelijking:** Hoe verhoudt Terraform zich tot alternatieven?

## Analyse & Resultaten
### Wat doet Terraform op het gebied van orkestratie
Terraform is een Infrastructure-as-Code (IaC) tool ontwikkeld door HashiCorp die infrastructuur declaratief beschrijft en beheert. In plaats van handmatig resources te configureren of scripts te schrijven die stap voor stap instructies uitvoeren, definieert Terraform de gewenste eindsituatie van de infrastructuur in configuratiebestanden geschreven in HCL (HashiCorp Configuration Language).

Bij elke uitvoering vergelijkt Terraform deze gewenste toestand met de huidige toestand (de state) en bepaalt het vervolgens welke veranderingen nodig zijn om de infrastructuur in lijn te brengen met wat in de code is gedefinieerd. Zo worden alleen de noodzakelijke aanpassingen uitgevoerd, wat leidt tot voorspelbare, herhaalbare en gecontroleerde wijzigingen.

Hoewel Terraform soms in dezelfde adem wordt genoemd als orkestratie-tools, valt het strikt genomen niet onder orkestratie. Terraform orkestreert geen processen of runtime-workflows (zoals de volgorde van containerdeployments of applicatie-updates), maar richt zich op provisioning en lifecycle management van infrastructuurcomponenten: het aanmaken, wijzigen en verwijderen van resources zoals virtuele machines, netwerken, databases en Kubernetes-clusters.

Waar een echte orkestratie-tool zoals Kubernetes, Ansible of Nomad zich richt op het beheren van runtime-processen en het coördineren van operationele taken, fungeert Terraform als de fundering waarop die systemen draaien. Het bouwt de infrastructuur waarop orkestratie plaatsvindt.

Kernpunten:
- **Declaratief model:** Terraform beschrijft de gewenste eindsituatie van infrastructuur in plaats van de afzonderlijke stappen om daar te komen.
- **Dependency-graph:** Terraform analyseert afhankelijkheden tussen resources en bepaalt automatisch de juiste volgorde van uitvoering.
- **Provider-onafhankelijk:** Ondersteunt honderden providers (AWS, Azure, Google Cloud, Kubernetes, Docker, VMware, enz.) via een uniform model.
- **Lifecycle management:** Beheert de volledige levenscyclus van infrastructuur - aanmaak, wijziging en verwijdering - op basis van statefiles.
- **Niet-orchestration, maar provisioning:** Terraform richt zich op het opbouwen en onderhouden van infrastructuur, niet op het beheren van operationele processen of applicatiestromen.

### Integratie binnen CI/CD en versiebeheer
Terraform is goed te integreren binnen DevOps-processen:
- **Versiebeheer:** Configuratiebestanden worden opgeslagen in Git-repositories, waardoor wijzigingen traceerbaar zijn.
- **Automatisering:** Terraform kan via CI/CD worden uitgevoerd (bijvoorbeeld via Jenkins, GitLab CI, of GitHub Actions).
- **Plan/Apply-stappen:**
	- `terraform plan` toont de voorgenomen wijzigingen.
	- `terraform apply` voert ze gecontroleerd uit.
- **Remote State:** Voor teamsamenwerking kan de state worden opgeslagen in een centrale backend (zoals Terraform Cloud of S3).

Hierdoor past Terraform uitstekend binnen GitOps-principes: infrastructuurwijzigingen worden via pull requests goedgekeurd en automatisch uitgerold.

### Terraform & Kubernetes
Terraform en Kubernetes hebben een verschillende focus, maar vullen elkaar goed aan:
| Aspect          | Terraform                                                 | Kubernetes                                           |
| --------------- | --------------------------------------------------------- | ---------------------------------------------------- |
| Doel            | Beheren van infrastructuur (servers, netwerken, clusters) | Beheren van container workloads en services          |
| Type declaratie | Infrastructure as Code                                    | Container orchestration / declaratieve workloads     |
| Gebruiksmoment  | Voor het opzetten van onderliggende omgeving              | Voor het beheren van apps binnen die omgeving        |
| Relatie         | Terraform bouwt de omgeving waarin Kubernetes draait      | Kubernetes draait de applicaties binnen die omgeving |

Terraform **eindigt waar Kubernetes begint**: het creëert bijvoorbeeld een Kubernetes-cluster, waarna Helm of ArgoCD de applicaties binnen dat cluster kunnen uitrollen.

### Technische haalbaarheid
Er is een eenvoudig prototype opgezet om de werking van Terraform te demonstreren.
Hiervoor is een "Hello World" applicatie in een Docker-container gebruikt.

Terraform-configuratie:
```hcl
resource "docker_image" "hello_world" {
  name = "hello-world-app"
  build {
    context = "../"
  }
}

resource "docker_container" "hello_container" {
  name  = "hello"
  image = docker_image.hello_world.latest
  ports {
    internal = 8080
    external = 8080
  }
}
```

**Resultaat:**
- Terraform bouwt en start automatisch een container met de applicatie.
- Configuratie is herhaalbaar en eenvoudig aan te passen.
- Laat zien dat IaC toepasbaar is zonder cloudprovider.

### Vergelijking met alternatieven
| Tool          | Type                       | Sterke punten                                  | Beperkingen                                         |
| ------------- | -------------------------- | ---------------------------------------------- | --------------------------------------------------- |
| **Ansible**   | Configuratiebeheer         | Makkelijk voor provisioning en updates         | Imperatief, minder geschikt voor declaratieve infrastructuur |
| **Helm**      | Kubernetes package manager | Ideaal voor applicatie-deploys binnen clusters | Geen infrastructuurbeheer                           |
| **ArgoCD**    | GitOps voor Kubernetes     | Geautomatiseerde applicatie-synchronisatie     | Richt zich niet op infrastructuur                   |
| **Pulumi**    | IaC met programmeertalen   | Flexibeler (Python, TS, Go, C#)                | Complexer en minder declaratief                     |
| **Terraform** | Multi-provider IaC         | Declaratief, multi-cloud, stabiel              | State management en lock-beheer vergen discipline   |

#### Voordelen van Terraform
- Declaratief, voorspelbaar en herhaalbaar.
- Breed ecosysteem en sterke community.
- Goede integratie met CI/CD en versiebeheer.
- Provider-onafhankelijk en multi-cloud compatibel.
- Helder onderscheid tussen infrastructuur en applicatielaag.

#### Nadelen
- Kan complex worden bij grote of dynamische omgevingen.
- State management vereist zorgvuldigheid.
- Geen directe ondersteuning voor applicatie-updates (daarvoor Kubernetes/Helm).
- Minder geschikt voor runtime-configuratiebeheer dan tools als Ansible.

### Vergelijking met Pulumi
| Aspect                                 | Terraform                                                 | Pulumi                                                                             |
| -------------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **Taal / declaratie**                  | HCL (HashiCorp Configuration Language), declaratief       | Volledige programmeertalen (Python, TypeScript, Go, C#), imperatief of declaratief |
| **Leerbaarheid**                       | Eenvoudig te leren door declaratieve syntax               | Hogere leercurve, kennis van programmeertaal vereist                               |
| **Provider-ecosysteem**                | Breed: AWS, Azure, GCP, Kubernetes, Docker, etc.          | Even breed; vaak dezelfde providers, maar gebruikt SDK's van providers             |
| **State management**                   | Eigen statefile (`terraform.tfstate`), kan remote         | Beheert state in cloud of lokaal; Pulumi Cloud biedt extra features                |
| **Integratie met CI/CD**               | Goed: plan/apply stappen, outputs makkelijk door te geven | Goed: kan volledig in programmeertaal pipeline integreren                          |
| **Herbruikbaarheid / modulariteit**    | Modules                                                   | Volledige programmeertaalstructuren -> loops, functies, packages                    |
| **Declaratieve vs imperatieve aanpak** | Strict declaratief                                        | Imperatief of declaratief -> meer flexibiliteit maar kan inconsistentie veroorzaken |
| **Community & tooling**                | Groot, volwassen, veel modules                            | Groeiend, minder volwassen, maar krachtiger voor complexe logica                   |

#### Belangrijkste verschillen
1. Programmeertaal vs configuratie
	- Pulumi laat je dezelfde kracht als een programmeertaal gebruiken: loops, conditionals, functies, objecten.
	- Terraform blijft strikt declaratief, waardoor het voorspelbaarder en makkelijker te auditen is.
2. Complexe logica
	- Pulumi kan complexere deploy-logica makkelijker aan: bijvoorbeeld dynamische resources gebaseerd op runtime-data.
	- Terraform kan dit met count, for_each, dynamic blocks, maar is beperkter.
3. Team en adoptie
	- Voor kleine tot middelgrote teams is Terraform eenvoudiger en veiliger door declaratieve aard.
	- Pulumi is krachtiger voor teams die al sterke programmeerkennis hebben en meer flexibiliteit nodig hebben.

## Conclusie
**Terraform** is een stabiele en volwassen IaC-tool die zeer geschikt is voor het declaratief beheren van infrastructuur. Het biedt sterke voordelen voor herhaalbaarheid, versiebeheer en integratie met DevOps-processen. Terraform eindigt waar Kubernetes begint, waardoor applicaties via Helm of ArgoCD kunnen worden uitgerold.

**Pulumi** biedt meer flexibiliteit door volledige programmeertalen te gebruiken en is krachtiger bij dynamische infrastructuur en complexe logica. Dit kan aantrekkelijk zijn voor teams die al programmeerkennis hebben, maar brengt een hogere leercurve en mogelijk minder voorspelbaarheid met zich mee.

Beide tools hebben duidelijke voor- en nadelen, waardoor de keuze afhangt van de gewenste balans tussen stabiliteit, eenvoud en flexibiliteit.

### Advies
Op basis van de uitgevoerde spike en de analyse van alternatieven wordt aanbevolen om Terraform als primaire Infrastructure-as-Code tool te implementeren voor het beheren van de onderliggende infrastructuur binnen onze applicatie-architectuur.

**Motivatie:**
1. **Duidelijke scheiding van verantwoordelijkheden:**
Terraform kan verantwoordelijk zijn voor het opzetten en beheren van de infrastructuur en Kubernetes-clusters, waarna Kubernetes, Helm of ArgoCD de applicaties en workloads beheren. Deze scheiding zorgt voor overzicht en eenvoud in beheer.
2. **Beperkt belang van runtime-complexiteit:**
Omdat de applicatie en workloads binnen Kubernetes draaien, is de behoefte aan dynamische of complexe runtime-logica binnen de infrastructuur beperkt. Hierdoor zijn de krachtige programmeerfuncties van Pulumi minder relevant, en volstaat het declaratieve karakter van Terraform.
3. **Stabiliteit en voorspelbaarheid:**
Terraform biedt een stabiele en declaratieve aanpak, waardoor infrastructuurwijzigingen voorspelbaar en herhaalbaar zijn, en eenvoudig kunnen worden geaudit.
4. **Integratie met bestaande processen:**
Terraform integreert goed met CI/CD-pipelines en versiebeheer, waardoor wijzigingen gecontroleerd en geautomatiseerd uitgerold kunnen worden.
5. **Brede ondersteuning en volwassen ecosysteem:**
Met een groot aantal providers en modules kunnen we multi-cloud- en hybride omgevingen eenvoudig beheren, zonder afhankelijk te zijn van specifieke programmeertalen of extra tooling.

Gezien de duidelijke grenzen met Kubernetes, het beperkte belang van runtime-flexibiliteit en de behoefte aan een stabiele, declaratieve en reproduceerbare infrastructuur, is Terraform de meest geschikte keuze voor onze organisatie.

Pulumi blijft een interessant alternatief voor scenario's waarbij zeer dynamische infrastructuur of complexe programmeerlogica vereist is, maar binnen onze huidige context is dit minder relevant en voegt het extra complexiteit toe die we kunnen vermijden.

## Bronnen
- HashiCorp. (z.d.). *Terraform-documentatie*. Geraadpleegd op 8 oktober 2025, van https://developer.hashicorp.com/terraform/docs
- Spacelift. (2025, 5 augustus). *Terraform vs. Kubernetes: Belangrijkste verschillen en vergelijking*. Geraadpleegd op 8 oktober 2025, van https://spacelift.io/blog/terraform-vs-kubernetes
- Buildkite. (2023, 7 september). *Een gids voor best practices voor Terraform CI/CD-workflows*. Geraadpleegd op 8 oktober 2025, van https://buildkite.com/resources/blog/best-practices-for-terraform-ci-cd/
- Spacelift. (2025, 14 april). *Hoe je je infrastructuur in CI/CD kunt implementeren met Terraform*. Geraadpleegd op 8 oktober 2025, van https://spacelift.io/blog/terraform-in-ci-cd
- Pulumi. (z.d.). *Pulumi vs. Terraform: Belangrijkste verschillen en vergelijking*. Geraadpleegd op 8 oktober 2025, van https://spacelift.io/blog/pulumi-vs-terraform
- KaaIoT Technologies, LLC. (2024, 1 maart). *Kubernetes vs. Terraform: Voor- en nadelen & vergelijking*. Geraadpleegd op 8 oktober 2025, van https://www.kaaiot.com/iot-knowledge-base/kubernetes-vs-terraform-pros-cons-and-differences
- Medium. (2025, 1 januari). *Terraform Best Practices voor CI/CD-pijplijnen*. Geraadpleegd op 8 oktober 2025, van https://terrateam.io/blog/terraform-best-practices-ci-cd
- Medium. (2025, 1 januari). *Terraform vs. Ansible vs. Pulumi: Welke moet je leren?*. Geraadpleegd op 8 oktober 2025, van https://medium.com/@bhavyansh001/terraform-vs-ansible-vs-pulumi-which-one-should-you-learn-first-e70778ed00a3
- Spacelift. (2025, 5 augustus). *Top 8 GitOps-tools die je moet kennen [2025-lijst]*. Geraadpleegd op 8 oktober 2025, van https://spacelift.io/blog/gitops-tools
- HashiCorp. (2020, 23 maart). *Leer CI/CD-automatisering met Terraform en CircleCI*. Geraadpleegd op 8 oktober 2025, van https://www.hashicorp.com/en/blog/learn-ci-cd-automation-with-terraform-and-circleci