local HttpService = game:GetService("HttpService")

local Webhook = {}

local WEBHOOK_URL = "https://discord.com/api/webhooks/1380694630106140854/rNvNZMpLgKzE2r8AyvqfU7RZpJEMfneC9M25Mvy8VgYqx83ZIb2EyYgj4vDogLNdhvky"

function Webhook.SendFruitEmbed(fruitName, playerCount, sea, jobId)
    local embed = {
        title = "🍎 Fruits",
        fields = {
            {
                name = "Spawned Fruit",
                value = fruitName,
                inline = false
            },
            {
                name = "Server",
                value = string.format("Players: %s\nSea: %s", playerCount, sea),
                inline = false
            },
            {
                name = "Job Id",
                value = jobId,
                inline = false
            }
        },
        footer = {
            text = "SCRbLx"
        },
        color = 16711680 -- warna merah (seperti contoh embed-mu)
    }

    local data = {
        embeds = {embed}
    }

    local success, response = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(data))
    end)

    if success then
        print("[Webhook] Fruit embed sent successfully.")
    else
        warn("[Webhook] Failed to send embed: " .. tostring(response))
    end
end

return Webhook
