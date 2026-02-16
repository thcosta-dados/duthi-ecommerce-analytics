#  Dashboard de Análise de E-commerce Duthi – Power BI

##  Visão Geral do Projeto

Este projeto apresenta um **Dashboard Interativo de E-commerce** desenvolvido no Power BI para a **Duthi** (marca de semijoias).
O objetivo é permitir que os stakeholders monitorem e analisem as principais métricas de vendas, o desempenho do mix de produtos (Prata vs. Ouro) e o comportamento de retenção de clientes ao longo de um período de 15 meses (Jul/2024 - Set/2025).

---

##  Visualização do Dashboard

![Visão Geral do Dashboard](Duthi_Ecommerce_Analytics.png)

---

##  Objetivos de Negócio

* Rastrear o faturamento total, volume de pedidos e tendências de ticket médio.
* Analisar o desempenho dos produtos por categoria (Brincos, Colares, etc.) e tipo de material.
* Identificar gargalos críticos na retenção de clientes (Análise de Churn).
* Avaliar tendências sazonais (melhores dias da semana para vendas).
* Habilitar a tomada de decisão baseada em dados para campanhas de marketing e reposição de estoque.

---

##  Engenharia de Dados (ETL & Pipeline)

Antes da visualização, foi desenvolvido um pipeline de engenharia de dados robusto para garantir a integridade e segurança das informações:

1.  **Pipeline ETL com Python:** Desenvolvimento de script (`etl_completo.py`) utilizando `Pandas` para extração, limpeza e tipagem dos dados brutos (CSV).
2.  **Conformidade com LGPD:** Implementação de algoritmos de *hashing* (SHA-256) para anonimizar dados sensíveis dos clientes (CPF, E-mail, Telefone) antes da carga no banco.
3.  **Modelagem Dimensional (Star Schema):** Estruturação do banco de dados PostgreSQL em tabelas Fato (Transações) e Dimensão (Produtos/Calendário).
4.  **Views Otimizadas:** Criação de 9 Views SQL para pré-processar agregações complexas e entregar dados leves ao Power BI.

---

##  Principais KPIs

* **Faturamento Total:** R$ 16,1 Mil
* **Total de Pedidos:** 200
* **Ticket Médio:** R$ 80,6
* **Clientes Únicos:** 189
* **Taxa de Retenção:** ~7% (93% dos clientes compraram apenas uma vez)

---

##  Funcionalidades do Dashboard

* **Visão Executiva (One-Page):** Visualização consolidada de todas as métricas críticas em uma única tela.
* **Classificação Automática de Material:** Lógica DAX para categorizar produtos automaticamente entre "Prata 925" e "Banhado a Ouro".
* **Sistema de Alerta de Retenção:** Destaque visual para baixas taxas de retenção com estimativa de impacto financeiro.
* **Análise Sazonal:** Detalhamento do desempenho de vendas por dia da semana.
* **Ranking de Top Categorias:** Visualização da distribuição de receita por tipo de produto.
* **Filtros Interativos:** Segmentação de dados por data para análises aprofundadas.

---

##  Ferramentas e Tecnologias

* **Power BI** (Desktop)
* **Python (Pandas & Hashlib)** para ETL e Anonimização de Dados.
* **SQL (PostgreSQL)** para Modelagem de Dados e Views.
* **DAX** (Data Analysis Expressions) para medidas de negócio.
* **Microsoft Excel / CSV** como fontes de dados originais.

---

##  Habilidades Demonstradas

* **Engenharia de Dados:** Pipeline ETL, Limpeza de Dados e Anonimização (Segurança).
* **Modelagem de Dados:** Implementação de Star Schema e relacionamentos.
* **DAX Avançado:** Uso de `SWITCH`, `SEARCH` e `CALCULATE`.
* **Design de Dashboard:** UI/UX moderna (Paleta personalizada, bordas arredondadas, neumorfismo).
* **Storytelling de Dados:** Transformação de números em insights de negócio acionáveis.

---

##  Principais Insights

* **Problema Crítico de Retenção:** 93% dos clientes não retornam para uma segunda compra, representando uma perda potencial de receita de ~R$ 6.500/ano.
* **Preferência de Material:** "Prata 925" impulsiona a maioria do volume de vendas (~62%) em comparação com itens Banhados a Ouro.
* **Top Categoria:** "Brincos" são a categoria mais vendida, representando 42% da receita total.
* **Melhores Dias de Venda:** Sexta-feira e Quinta-feira apresentam os maiores tickets médios, ideais para o lançamento de novas coleções.

---

##  Arquivos do Projeto

* `Duthi_Ecommerce_Analytics.pbix` – Arquivo do relatório Power BI.
* `etl_script.py` – Script Python utilizado para processamento dos dados.

---

##  Como Usar

1.  Baixe o arquivo `.pbix` deste repositório.
2.  Abra no **Power BI Desktop**.
3.  Use o filtro de data (canto superior direito) para interagir com o dashboard.
4.  Passe o mouse sobre os gráficos para ver detalhes específicos (Tooltips).

---

##  Feedback e Contato

Feedbacks e sugestões são bem-vindos.
Sinta-se à vontade para se conectar comigo no LinkedIn para discussões e colaboração.

* **LinkedIn:** [Acessar meu Perfil](https://www.linkedin.com/in/thiago-costa-dados/)

---

## 🏷 Tags

Power BI | Data Engineering | ETL | Python | SQL | Dashboard Design | DAX | Business Intelligence
