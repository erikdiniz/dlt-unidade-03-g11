// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title SPDIRegistry — âncora de integridade de decisões judiciais e provas digitais
/// @notice Registra o compromisso criptográfico (hash SHA-256 + metadados) de documentos.
///         Nenhum conteúdo de documento é armazenado on-chain, apenas o hash.
/// @dev Escrita restrita a REGISTRAR_ROLE; leitura pública. Transições ilegais
///      revertem com erro explícito — sem correção silenciosa.
contract SPDIRegistry is AccessControl {
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    enum EstadoDocumento {
        Publicado,
        Retificado,
        Arquivado
    }

    enum TipoArtefato {
        DecisaoJudicial,
        ProvaDigital
    }

    struct Documento {
        bytes32 id;
        bytes32 hashAtual;
        string processoId;
        TipoArtefato tipo;
        EstadoDocumento estado;
        address remetente;
        uint256 timestampRegistro;
        uint256 versao;
    }

    struct EventoCustodia {
        bytes32 docId;
        bytes32 hash;
        string acao;
        address autor;
        uint256 timestamp;
    }

    mapping(bytes32 => Documento) private documentos;
    mapping(bytes32 => bytes32) private hashParaDocId;
    mapping(bytes32 => EventoCustodia[]) private historico;

    event DocumentoRegistrado(
        bytes32 indexed docId,
        bytes32 indexed hash,
        string processoId,
        address indexed remetente
    );

    error HashInvalido();
    error HashJaRegistrado(bytes32 docIdExistente);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRAR_ROLE, msg.sender);
    }

    /// @notice Função central do SPDI: grava o compromisso criptográfico do documento.
    /// @param hash SHA-256 dos bytes do arquivo (calculado off-chain).
    /// @param processoId Identificador do processo judicial (formato CNJ).
    /// @param tipo DecisaoJudicial ou ProvaDigital.
    /// @return docId Identificador lógico do documento registrado.
    function registrarDocumento(
        bytes32 hash,
        string calldata processoId,
        TipoArtefato tipo
    ) external onlyRole(REGISTRAR_ROLE) returns (bytes32 docId) {
        if (hash == bytes32(0)) revert HashInvalido();
        if (hashParaDocId[hash] != bytes32(0)) {
            revert HashJaRegistrado(hashParaDocId[hash]);
        }

        docId = keccak256(abi.encode(hash, processoId));

        documentos[docId] = Documento({
            id: docId,
            hashAtual: hash,
            processoId: processoId,
            tipo: tipo,
            estado: EstadoDocumento.Publicado,
            remetente: msg.sender,
            timestampRegistro: block.timestamp,
            versao: 1
        });

        hashParaDocId[hash] = docId;

        historico[docId].push(
            EventoCustodia({
                docId: docId,
                hash: hash,
                acao: "registro",
                autor: msg.sender,
                timestamp: block.timestamp
            })
        );

        emit DocumentoRegistrado(docId, hash, processoId, msg.sender);
    }

    /// @notice Verificação pública: retorna o documento associado a um hash.
    /// @dev Documento com id zero significa "não encontrado" — interpretação
    ///      a cargo do chamador (backend/UI).
    function verificarHash(bytes32 hash) external view returns (Documento memory) {
        return documentos[hashParaDocId[hash]];
    }

    /// @notice Estado atual de um documento pelo seu id lógico.
    function obterDocumento(bytes32 docId) external view returns (Documento memory) {
        return documentos[docId];
    }

    /// @notice Cadeia de custódia completa (array append-only).
    function obterHistorico(bytes32 docId) external view returns (EventoCustodia[] memory) {
        return historico[docId];
    }
}