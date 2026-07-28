# Documentação de Classes e Contratos Inteligentes - SPDI

Este documento descreve a modelagem orientada a objetos dos smart contracts da solução **SPDI (Sistema de Prova Digital Imutável)**, detalhando os atributos, visibilidade, assinaturas de métodos e eventos emitidos[cite: 1, 2].

---

## 1. Diagrama UML de Classes (Mermaid)

```mermaid
classDiagram
    class AccessControl {
        <<abstract — OpenZeppelin>>
        +DEFAULT_ADMIN_ROLE bytes32
        +hasRole(role, conta) bool
        +grantRole(role, conta)
        +revokeRole(role, conta)
    }

    class SPDIRegistry {
        +REGISTRAR_ROLE bytes32
        -documentos mapping~bytes32, Documento~
        -hashParaDocId mapping~bytes32, bytes32~
        -historico mapping~bytes32, EventoCustodia[]~
        +registrarDocumento(hash, processoId, tipo) bytes32
        +retificarDocumento(docId, novoHash)
        +arquivarDocumento(docId)
        +verificarHash(hash) Documento
        +obterDocumento(docId) Documento
        +obterHistorico(docId) EventoCustodia[]
    }

    class Documento {
        <<struct>>
        +id bytes32
        +hashAtual bytes32
        +processoId string
        +tipo TipoArtefato
        +estado EstadoDocumento
        +remetente address
        +timestampRegistro uint256
        +versao uint256
    }

    class EventoCustodia {
        <<struct>>
        +docId bytes32
        +hash bytes32
        +acao string
        +autor address
        +timestamp uint256
    }

    class EstadoDocumento {
        <<enumeration>>
        Publicado
        Retificado
        Arquivado
    }

    class TipoArtefato {
        <<enumeration>>
        DecisaoJudicial
        ProvaDigital
    }

    class Events {
        <<events>>
        DocumentoRegistrado(docId, hash, processoId, remetente)
        DocumentoRetificado(docId, novoHash, remetente)
        DocumentoArquivado(docId, remetente)
    }

    AccessControl <|-- SPDIRegistry : herda
    SPDIRegistry "1" *-- "N" Documento : armazena
    SPDIRegistry "1" *-- "N" EventoCustodia : histórico append-only
    SPDIRegistry ..> Events : emite
    Documento --> EstadoDocumento : estado
    Documento --> TipoArtefato : tipo

    note for SPDIRegistry "Escrita (registrar, retificar, arquivar):
somente onlyRole(REGISTRAR_ROLE).
Leitura (verificar, obter): pública, view.
Transições ilegais revertem com erro explícito."

    note for EstadoDocumento "Transições legais:
Publicado → Retificado (repetível)
Publicado ou Retificado → Arquivado
Arquivado é terminal.
Retificar não apaga o histórico."