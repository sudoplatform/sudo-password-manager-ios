import Foundation
import SudoSecureVault

/// Definitions for the vault schema.
/// Provides encoding/decoding of vaults from the `SecureVault` format spoken by the secure vault service,
/// and the vault format used by the internal `VaultStore` used by the password manager client.
enum VaultSchema: String {

    /// Define the latest model versions (i.e. namespace by enum).
    /// If defining a new version of the schema, you should only need to change this
    /// to point to the latest models and the rest of the code should migrate types automatically
    /// Build errors would indicate the outward facing models need an update.
    typealias CurrentModelSchema = VaultSchema.VaultSchemaV1

    case v1 = "com.sudoplatform.passwordmanager.vault.v1"

    /// Latest version of the vault schema
    static var latest: VaultSchema = .v1

    /// Decodes the secure vault blob into the vault format used by the vault store
    func decodeSecureVault(vault: SudoSecureVault.Vault) throws -> VaultProxy {
        switch self {
        case .v1:
            let data = try VaultSchemaV1.Decoder().decode(data: vault.blob)
            return VaultProxy(secureVaultId: vault.id,
                              blobFormat: VaultSchema.latest,
                              createdAt: vault.createdAt,
                              updatedAt: vault.updatedAt,
                              version: vault.version,
                              owner: vault.owner,
                              owners: vault.owners.map({return VaultProxy.VaultOwner.init(id: $0.id, issuer: $0.issuer)}),
                              vaultData: data)
        }
    }

    /// Encodes a vault from the vault store into the latest schema so it can be updated
    /// on the service.
    static func encodeVaultWithLatestSchema(vault: VaultProxy) throws -> Data {

        let encoder = CurrentModelSchema.Encoder()

        do {
            let blob = try encoder.encode(vault: vault.vaultData)
            return blob
        } catch {
            throw error
        }
    }
}
