+++
title = 'Workflow'
date = 2024-03-08T20:35:23-08:00
draft = false
+++

{{< mermaid >}}
---
title:
---
flowchart TD
    Z([Experiment Accession Number]) -->|efetch run info| A([SRR Accession Numbers])
	X([Organism Assembly ID]) --> |Download from UCSC| C([Reference Genome])
    A -->|Download from ENA usig aria| B([FASTQs])
    C -->|Index reference genome| D([Indexed Reference Genome])
    B --> E[BWA Alignment]
    D --> E
    E --> F([BAM])
    F --> G[Merge Sequencing Runs<br>by Condition and reindex]
    G -->|Bedtools| H([BEDGraph])
    G -->|BEGgraphtoBigWig| I([BigWig])
    G -->|MACS2| J([Peak Files])
    G -->|MEME suite| K[Motif report]
    J --> L[Visualize with<br>UCSC Genome Browser]
	I --> L
	H --> L
{{< /mermaid >}}

### Details

- [Full analysis entry requirements](https://bio-recap.github.io/Liu_2016/entry_and_reqs/)
