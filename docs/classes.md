# Documentação de Classes e Contratos Inteligentes - SPDI

Este documento descreve a modelagem orientada a objetos dos smart contracts da solução **SPDI (Sistema de Prova Digital Imutável)**, detalhando os atributos, visibilidade, assinaturas de métodos e eventos emitidos.

---

## 1. Diagrama UML de Classes

```mermaid
classDiagram
    class StatusDocumento {
        <<enumeration>>
        PUBLICADO
        RETIFICADO
        ARQUIVADO
    }

    class Documento {
        +bytes32 hashDocumento
        +string idProcesso
        +uint256 timestamp
        +address registrador
        +StatusDocumento status
        +bytes32 hashSubstituto
    }

    class HistoricoRetificacao {
        +bytes32 hashAntigo
        +bytes32 hashNovo
        +string motivo
        +uint256 timestamp
        +address autor
    }

    class SPDI {
        -mapping~bytes32 => Documento~ _documentos
        -mapping~bytes32 => HistoricoRetificacao~ _retificacoes
        +address public owner

        +event DocumentoRegistrado(bytes32 indexed hashDocumento, string idProcesso, address indexed registrador, uint256 timestamp)
        +event StatusAtualizado(bytes32 indexed hashDocumento, StatusDocumento novoStatus, uint256 timestamp)
        +event DocumentoRetificado(bytes32 indexed hashAntigo, bytes32 indexed hashNovo, string motivo, address indexed autor)

        +registrarDocumento(bytes32 hashDocumento, string idProcesso) bool
        +retificarDocumento(bytes32 hashAntigo, bytes32 hashNovo, string motivo) bool
        +alterarStatus(bytes32 hashDocumento, StatusDocumento novoStatus) bool
        +verificarDocumento(bytes32 hashDocumento) Documento
        +obterRetificacao(bytes32 hashNovo) HistoricoRetificacao
        +existeDocumento(bytes32 hashDocumento) bool
    }

    SPDI "1" *-- "*" Documento : armazena
    SPDI "1" *-- "*" HistoricoRetificacao : registra
    Documento --> StatusDocumento : possui estado