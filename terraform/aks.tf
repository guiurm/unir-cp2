# ---------------------------------------------------------------------------
# Clúster AKS (Azure Kubernetes Service)
# ---------------------------------------------------------------------------

# Clúster Kubernetes gestionado por Azure.
# - identity SystemAssigned: Azure gestiona la identidad automáticamente.
# - 1 nodo worker: mínimo requerido por el enunciado.
# - role_based_access_control: habilitado por defecto en AKS moderno.
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.aks_dns_prefix
  tags                = local.common_tags

  # Identidad gestionada por el sistema (no requiere Service Principal manual)
  identity {
    type = "SystemAssigned"
  }

  # Pool de nodos por defecto: 1 worker tal como pide el enunciado
  default_node_pool {
    name       = "nodepool1"
    node_count = var.aks_node_count
    vm_size    = var.aks_node_vm_size
  }
}

# ---------------------------------------------------------------------------
# Permisos AcrPull: AKS puede descargar imágenes del ACR
# ---------------------------------------------------------------------------

# Asigna el rol AcrPull al kubelet del AKS sobre el ACR.
# Esto permite que los pods descarguen imágenes del registro privado sin credenciales adicionales.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_container_registry.acr
  ]
}
