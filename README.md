# Lovable Integration - Webhook & Terminal Receiver

Este projeto disponibiliza um servidor local (HTTP Webhook) e um terminal interativo em PowerShell/.NET nativo (sem depender de Node.js ou Python externos) para receber e exibir cadastros de Pessoa Física (PF) originados de um aplicativo ou protótipo gerado no **Lovable.dev**.

---

## 🚀 Como Executar

Abra o PowerShell nesta pasta e execute:

```powershell
.\iniciar_terminal.ps1
```

O servidor iniciará escutando na porta **`http://localhost:5000/`**.

---

## 📡 Endpoints Disponíveis

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/health` | Checagem de status da conexão |
| `POST` | `/api/cadastro` | Endpoint principal para receber dados do formulário PF via JSON |
| `OPTIONS` | `*` | Suporte completo a CORS (permite chamadas vindas de `https://*.lovable.app` ou `http://localhost:*`) |

---

## 📋 Estrutura do Payload (Cadastro PF)

O formulário no Lovable pode enviar os seguintes campos:

```json
{
  "nome": "João da Silva",
  "cpf": "123.456.789-00",
  "dataNascimento": "1990-05-15",
  "email": "joao.silva@exemplo.com",
  "telefone": "(11) 98765-4321",
  "cep": "01310-100",
  "logradouro": "Av. Paulista, 1000",
  "bairro": "Bela Vista",
  "cidade": "São Paulo",
  "uf": "SP",
  "observacoes": "Cadastro realizado via protótipo Lovable."
}
```

---

## 🎨 Como plugar no Lovable (Prompt ou Código)

No seu projeto do **Lovable**, você pode usar a seguinte função de envio no seu botão de submit:

```typescript
async function enviarCadastroPF(dados: any) {
  try {
    const response = await fetch("http://localhost:5000/api/cadastro", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(dados),
    });

    const resultado = await response.json();
    console.log("Resposta do Terminal:", resultado);
    alert("Cadastro enviado com sucesso para o Terminal!");
  } catch (error) {
    console.error("Erro ao conectar com o terminal local:", error);
    alert("Falha ao comunicar com o terminal local na porta 5000.");
  }
}
```

> **Dica para o Lovable**: Peça ao Lovable:  
> *"Adicione uma ação no botão 'Salvar Cadastro' que faz um POST com os dados preenchidos para `http://localhost:5000/api/cadastro` com tratamento de erro e feedback visual."*
