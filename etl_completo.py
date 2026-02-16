import pandas as pd
import hashlib
import sys

# --- CONFIGURAÇÕES GERAIS ---
ARQ_VENDAS = 'relatorio_duthi_pedidos_bruto.csv'
ARQ_PRODUTOS = 'duthi_produtos.csv'

# NOMES DEFINIDOS PELO USUÁRIO
# Serão criados 3 arquivos CSV com separador ';' prontos para SQL
SAIDA_PEDIDOS = 'pedidos.csv'
SAIDA_ITENS = 'itens_vendidos.csv'
SAIDA_PRODUTOS = 'catalogo_produtos.csv'

# --- CONFIGURAÇÕES DE TRANSFORMAÇÃO ---

# 1. Colunas Sensíveis (LGPD) - Serão transformadas em códigos
COLS_SENSIVEIS = [
    'customers__via__customer_id__name', 
    'customers__via__customer_id__email',
    'customers__via__customer_id__cgc', 
    'customers__via__customer_id__phone',
    'Order Addresses__receiver', 
    'Order Addresses__street', 
    'Order Addresses__number',
    'Order Addresses__zipcode'
]

# 2. Mapa de Renomeação - VENDAS (De -> Para)
MAPA_VENDAS = {
    'id': 'id_pedido',
    'created_at': 'data_pedido',
    'total': 'valor_total_pedido',
    'Order Shippings__price': 'valor_frete',
    'customers__via__customer_id__name': 'id_cliente_anonimo',
    'Products__id': 'id_produto',
    'Order Items__quantity': 'quantidade',
    'Order Items__price': 'preco_unitario_pago'
}

# 3. Mapa de Renomeação - PRODUTOS (De -> Para)
MAPA_PRODUTOS = {
    'product_id': 'id_produto',
    'name': 'nome_oficial',
    'category_1': 'categoria_principal',
    'category_2': 'categoria_secundaria',
    'category_3': 'categoria_terciaria',
    'brand': 'marca',
    'stock': 'estoque_atual',
    'active': 'status_ativo'
}

# --- FUNÇÕES AUXILIARES ---
def criar_hash(valor):
    """Gera um código único para anonimizar dados pessoais."""
    if pd.isna(valor) or str(valor).strip() == "":
        return "nao_informado"
    return hashlib.sha256(str(valor).encode('utf-8')).hexdigest()[:12]

# --- EXECUÇÃO DO PROCESSO ---
print("=" * 60)
print("🚀 INICIANDO ETL: DUTHI E-COMMERCE ANALYTICS")
print("=" * 60)

# ==============================================================================
# ETAPA A: PROCESSAR VENDAS
# ==============================================================================
try:
    print("\n📦 Lendo arquivo de vendas...")
    # Tenta ler com diferentes configurações para evitar erros
    try:
        df_vendas = pd.read_csv(ARQ_VENDAS, sep=',', encoding='utf-8')
    except:
        df_vendas = pd.read_csv(ARQ_VENDAS, sep=';', encoding='latin1')
    
    print(f"   ✅ {len(df_vendas)} linhas carregadas do arquivo bruto")

    # 1. Anonimização
    print("\n🔒 Anonimizando dados sensíveis (LGPD)...")
    for col in COLS_SENSIVEIS:
        if col in df_vendas.columns:
            df_vendas[col] = df_vendas[col].apply(criar_hash)

    # 2. Renomeação
    print("✏️  Renomeando colunas...")
    df_vendas.rename(columns=MAPA_VENDAS, inplace=True)

    # 3. Separação (Normalização)
    print("\n📊 Normalizando dados...")
    
    # Tabela 1: PEDIDOS (Uma linha por pedido, sem repetir itens)
    cols_pedidos = ['id_pedido', 'data_pedido', 'id_cliente_anonimo', 'valor_total_pedido', 'valor_frete']
    cols_ped_reais = [c for c in cols_pedidos if c in df_vendas.columns]
    df_pedidos = df_vendas[cols_ped_reais].drop_duplicates(subset=['id_pedido'])
    
    print(f"   ✅ Tabela PEDIDOS: {len(df_pedidos)} pedidos únicos")

    # Tabela 2: ITENS VENDIDOS (Uma linha por produto vendido)
    cols_itens = ['id_pedido', 'id_produto', 'quantidade', 'preco_unitario_pago']
    cols_itens_reais = [c for c in cols_itens if c in df_vendas.columns]
    df_itens = df_vendas[cols_itens_reais].copy()  # .copy() para evitar warnings
    
    # 🆕 MELHORIA 1: Adicionar coluna calculada (valor total do item)
    print("➕ Calculando valor_total_item...")
    df_itens['valor_total_item'] = df_itens['quantidade'] * df_itens['preco_unitario_pago']
    
    print(f"   ✅ Tabela ITENS: {len(df_itens)} itens vendidos")

except Exception as e:
    print(f"❌ Erro crítico em Vendas: {e}")
    sys.exit()

# ==============================================================================
# ETAPA B: PROCESSAR PRODUTOS (CATÁLOGO)
# ==============================================================================
try:
    print("\n📦 Lendo catálogo de produtos...")
    df_prod = pd.read_csv(ARQ_PRODUTOS, sep=',') 
    
    colunas_desejadas = list(MAPA_PRODUTOS.keys())
    cols_existentes = [c for c in colunas_desejadas if c in df_prod.columns]
    
    df_produtos = df_prod[cols_existentes].copy()
    df_produtos.rename(columns=MAPA_PRODUTOS, inplace=True)

    # Limpeza básica (Remove produtos sem nome ou ID)
    print("🧹 Limpando dados de produtos...")
    antes = len(df_produtos)
    df_produtos.dropna(subset=['id_produto', 'nome_oficial'], inplace=True)
    df_produtos.drop_duplicates(subset=['id_produto'], inplace=True)
    depois = len(df_produtos)
    
    print(f"   ✅ Produtos: {depois} únicos (removidos {antes - depois} duplicados/inválidos)")

except Exception as e:
    print(f"❌ Erro crítico em Produtos: {e}")
    sys.exit()

# ==============================================================================
# 🆕 MELHORIA 2: VALIDAÇÃO DE CHAVES ESTRANGEIRAS
# ==============================================================================
print("\n🔍 Validando integridade dos dados...")

# Verificar se todos os produtos vendidos existem no catálogo
produtos_validos = set(df_produtos['id_produto'].unique())
produtos_vendidos = set(df_itens['id_produto'].unique())
produtos_orfaos = produtos_vendidos - produtos_validos

if produtos_orfaos:
    print(f"   ⚠️  ATENÇÃO: {len(produtos_orfaos)} produtos vendidos não estão no catálogo:")
    print(f"      IDs órfãos: {list(produtos_orfaos)[:5]}...")  # Mostra só os 5 primeiros
    
    # Remove itens de produtos que não existem no catálogo
    print("   🧹 Removendo itens órfãos...")
    df_itens_validos = df_itens[df_itens['id_produto'].isin(produtos_validos)]
    itens_removidos = len(df_itens) - len(df_itens_validos)
    df_itens = df_itens_validos
    print(f"   ✅ {itens_removidos} itens órfãos removidos")
else:
    print("   ✅ Todos os produtos vendidos existem no catálogo!")

# ==============================================================================
# ETAPA C: SALVAR ARQUIVOS
# ==============================================================================
print("\n💾 SALVANDO ARQUIVOS FINAIS...")
print("-" * 60)

df_pedidos.to_csv(SAIDA_PEDIDOS, index=False, sep=';', encoding='utf-8')
print(f"✅ {SAIDA_PEDIDOS}")
print(f"   • {len(df_pedidos)} pedidos salvos")

df_itens.to_csv(SAIDA_ITENS, index=False, sep=';', encoding='utf-8')
print(f"✅ {SAIDA_ITENS}")
print(f"   • {len(df_itens)} itens salvos")

df_produtos.to_csv(SAIDA_PRODUTOS, index=False, sep=';', encoding='utf-8')
print(f"✅ {SAIDA_PRODUTOS}")
print(f"   • {len(df_produtos)} produtos salvos")

# ==============================================================================
# 🆕 MELHORIA 3: ESTATÍSTICAS FINAIS
# ==============================================================================
print("\n" + "=" * 60)
print("📊 RESUMO DO PROCESSAMENTO")
print("=" * 60)

faturamento_total = df_pedidos['valor_total_pedido'].sum()
frete_total = df_pedidos['valor_frete'].sum()
ticket_medio = df_pedidos['valor_total_pedido'].mean()

print(f"💰 Faturamento Total:     R$ {faturamento_total:,.2f}")
print(f"🚚 Frete Total:           R$ {frete_total:,.2f}")
print(f"🎯 Ticket Médio:          R$ {ticket_medio:,.2f}")
print(f"📦 Total de Pedidos:      {len(df_pedidos)}")
print(f"🛒 Total de Itens:        {len(df_itens)}")
print(f"🏷️  Produtos no Catálogo:  {len(df_produtos)}")

print("\n" + "=" * 60)
print("✨ ETL CONCLUÍDO COM SUCESSO! ✨")
print("=" * 60)
print("\n👉 Próximo passo: Importar os CSVs para o PostgreSQL\n")