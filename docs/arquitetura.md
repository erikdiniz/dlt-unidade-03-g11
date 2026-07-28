# Diagrama de Arquitetura da Solução - SPDI

Este documento especifica a arquitetura de alto e médio nível do **Sistema de Prova Digital Imutável (SPDI)**, detalhando a comunicação entre os componentes e a fronteira entre a infraestrutura Off-Chain e On-Chain.

```mermaid
flowchart TB
    subgraph atores["Atores"]
        REG["Registrador autenticado<br/>(magistrado, servidor, advogado)"]
        VER["Verificador público<br/>(pessoa ou sistema)"]
        AUD["Auditor"]
    end

    subgraph offchain["OFF-CHAIN"]
        MOCK["Mock SEI/PJe<br/>simula juntada / assinatura<br/>(API REST)"]

        subgraph frontend["Frontend"]
            UIPUB["UI pública de verificação<br/>upload do PDF<br/>íntegro / divergente / não encontrado"]
            DASH["Dashboard de auditoria<br/>histórico + alertas<br/>(autenticado)"]
        end

        subgraph backend["Backend API"]
            HASH["Serviço de hashing<br/>SHA-256 canônico<br/>fonte única de verdade"]
            SREG["Serviço de registro<br/>(autenticado, escrita)"]
            SVER["Serviço de verificação<br/>(público, somente leitura)"]
            CLI["Cliente blockchain<br/>(ethers.js)"]
        end

        DB[("Base de auditoria<br/>log de verificações<br/>e alertas de divergência")]
    end

    subgraph onchain["ON-CHAIN — nó EVM (Hardhat / testnet)"]
        SC["Contrato SPDIRegistry<br/>hash + timestamp do bloco<br/>+ id do processo + remetente<br/>+ estado + tipo de artefato"]
    end

    REG -->|"junta prova / assina decisão"| MOCK
    MOCK -->|"evento de juntada/assinatura<br/>+ arquivo"| SREG
    SREG -->|"calcula hash<br/>(bytes descartados)"| HASH
    SREG --> CLI
    CLI -->|"tx: registrar / retificar / arquivar"| SC

    VER -->|"upload do arquivo"| UIPUB
    UIPUB --> SVER
    SVER -->|"recomputa o hash"| HASH
    SVER --> CLI
    CLI -->|"consulta (view, sem tx)"| SC
    SVER -->|"registra alerta<br/>se divergente"| DB

    AUD --> DASH
    DASH -->|"eventos on-chain"| CLI
    DASH -->|"alertas off-chain"| DB