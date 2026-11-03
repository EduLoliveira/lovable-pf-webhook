$payload = @{
    nome = "Mariana Rodrigues Silva"
    cpf = "342.871.908-11"
    dataNascimento = "1994-08-22"
    email = "mariana.silva@exemplo.com.br"
    telefone = "(11) 97123-4567"
    cep = "04571-010"
    logradouro = "Av. Eng. Luís Carlos Berrini, 105"
    bairro = "Itaim Bibi"
    cidade = "São Paulo"
    uf = "SP"
    observacoes = "Enviado a partir de teste automatizado simulando o Lovable"
} | ConvertTo-Json

Write-Host "Enviando payload de teste para http://localhost:5000/api/cadastro..." -ForegroundColor Cyan
try {
    $res = Invoke-RestMethod -Uri "http://localhost:5000/api/cadastro" -Method POST -Body $payload -ContentType "application/json"
    Write-Host "Resposta do Servidor:" -ForegroundColor Green
    $res | Format-List
} catch {
    Write-Host "Falha no envio: $($_.Exception.Message)" -ForegroundColor Red
}
