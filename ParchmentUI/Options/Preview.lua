local ADDON_NAME, ns = ...

-- A sample scroll built entirely from the addon's own frames. It shows the artwork, fonts,
-- colors, docking and unroll animation without touching any Blizzard window, so the look can
-- be checked on its own and it is safe to open at any time, including in combat.
local Preview = {}
ns.Preview = Preview

local WIDTH, HEIGHT = 384, 512
local PADDING = 40

local frame
local parts
-- True while the close animation runs: the frame is still shown but is on its way out.
local closing = false

local function NewText(parent)
    local text = parent:CreateFontString(nil, "OVERLAY")
    -- Text cannot be set on a font string that has no font yet, and in locales that keep the
    -- client font the theme does not supply one.
    if GameFontNormal then
        text:SetFontObject(GameFontNormal)
    end
    return text
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    parts = {}
    parts.title = NewText(frame)
    parts.title:SetPoint("TOP", frame, "TOP", 0, -PADDING)

    parts.divider = frame:CreateTexture(nil, "ARTWORK")
    parts.divider:SetTexture(ns.Textures.Get("divider"))
    parts.divider:SetSize(WIDTH - 2 * PADDING, 8)
    parts.divider:SetPoint("TOP", parts.title, "BOTTOM", 0, -10)

    parts.body = NewText(frame)
    parts.body:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING - 56)
    parts.body:SetWidth(WIDTH - 2 * PADDING)
    parts.body:SetJustifyH("LEFT")

    parts.button = CreateFrame("Button", nil, frame)
    parts.button:SetSize(128, 36)
    parts.button:SetPoint("BOTTOM", frame, "BOTTOM", 0, PADDING + 8)
    parts.button:SetScript("OnClick", Preview.Hide)

    parts.outline = parts.button:CreateTexture(nil, "BACKGROUND")
    parts.outline:SetTexture(ns.Textures.Get("buttonOutline"))
    parts.outline:SetAllPoints(parts.button)
    local _, _, margin = ns.Textures.Info("buttonOutline")
    if type(parts.outline.SetTextureSliceMargins) == "function" then
        parts.outline:SetTextureSliceMargins(margin, margin, margin, margin)
    end

    parts.label = NewText(parts.button)
    parts.label:SetPoint("CENTER", parts.button, "CENTER", 0, 0)
end

local function Style(theme)
    local L = ns.L
    local ink = theme.colors.body
    parts.scroll = ns.Scroll.Apply(frame, theme)

    ns.Skin.SetFont(parts.title, theme, "heading", 22)
    ns.Skin.SetFont(parts.body, theme, "body", 15)
    ns.Skin.SetFont(parts.label, theme, "body", 15)
    ns.Skin.ColorText(parts.title, theme, "heading")
    ns.Skin.ColorText(parts.body, theme, "body")
    ns.Skin.ColorText(parts.label, theme, "body")
    parts.divider:SetVertexColor(ink[1], ink[2], ink[3])
    parts.outline:SetVertexColor(ink[1], ink[2], ink[3])

    parts.title:SetText(L.PREVIEW_TITLE)
    parts.body:SetText(L.PREVIEW_BODY)
    parts.label:SetText(L.PREVIEW_CLOSE)
end

local function Place()
    if not UIParent then
        return
    end
    local screen = { width = UIParent:GetWidth(), height = UIParent:GetHeight() }
    local window = { id = "preview", width = WIDTH, height = HEIGHT }
    local slot = ns.Layout.Compute(screen, ns.Layout.Options(), { window })[1]
    frame:ClearAllPoints()
    frame:SetScale(slot.scale)
    -- Anchor offsets are measured in the frame's own scaled units, while the slot is in
    -- screen units.
    frame:SetPoint(slot.point, UIParent, slot.point, slot.x / slot.scale, slot.y / slot.scale)
end

local function Reveal(alpha, reveal)
    ns.Scroll.SetReveal(parts.scroll, alpha, reveal)
    -- Contents appear once the sheet has unrolled past them, not while it is still closed.
    local contentAlpha = alpha * reveal
    parts.title:SetAlpha(contentAlpha)
    parts.divider:SetAlpha(contentAlpha)
    parts.body:SetAlpha(contentAlpha)
    parts.button:SetAlpha(contentAlpha)
end

-- True while the preview is open and not already rolling up.
function Preview.IsShown()
    return frame ~= nil and frame:IsShown() and not closing
end

function Preview.Show()
    if not frame then
        Build()
    end
    Style(ns.Theme.Current())
    Place()
    closing = false
    frame:Show()
    ns.Animation.Play(frame, true, Reveal)
end

function Preview.Hide()
    if not Preview.IsShown() then
        return
    end
    closing = true
    ns.Animation.Play(frame, false, Reveal, function()
        frame:Hide()
        closing = false
    end)
end

-- A preview that is already rolling up counts as closed, so a second command reopens it.
function Preview.Toggle()
    if Preview.IsShown() then
        Preview.Hide()
    else
        Preview.Show()
    end
end

-- Restyle and move an open preview as soon as an option changes, so settings can be tried
-- live.
ns.Options.Subscribe(function()
    if Preview.IsShown() then
        Style(ns.Theme.Current())
        Place()
    end
end)
