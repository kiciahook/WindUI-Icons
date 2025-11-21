type NewInstanceWrapper = (className: string, properties: { [string]: any }) -> Instance

type IconSets = { [IconType]: IconSetData }
type IconType = "lucide" | "craft" | "geist" | "sfsymbols"
type IconSetData = {
    Icons: { [string]: IconsMeta },
    Spritesheets: { [string]: string },

    [string]: any,
}
type IconsMeta = {
    Image: string?,
    ImageRectPosition: Vector2?,
    ImageRectSize: Vector2?,
    Parts: { [number]: string }?,
}

local Icons = {
    New = (nil :: any) :: NewInstanceWrapper?,

    IconsType = "lucide" :: IconType,
    IconThemeTag = (nil :: any) :: Color3?,

    _iconSets = {} :: IconSets,
}

local ICON_FETCH_URLS = {
    ["lucide"] = "https://raw.githubusercontent.com/kiciahook/WindUI-Icons/refs/heads/main/lucide/dist/Icons.luau",
    ["craft"] = "https://raw.githubusercontent.com/kiciahook/WindUI-Icons/refs/heads/main/craft/dist/Icons.luau",
    ["geist"] = "https://raw.githubusercontent.com/kiciahook/WindUI-Icons/refs/heads/main/geist/dist/Icons.luau",
    ["sfsymbols"] = "https://raw.githubusercontent.com/kiciahook/WindUI-Icons/refs/heads/main/sfsymbols/dist/Icons.luau",
}

local function parseIconString(iconString: string): (IconType?, string)
    -- Colon indicates that the type and name are packed together e.g. lucide:icon-name-here.
    local splitIndex = iconString:find(":")
    if splitIndex ~= nil then
        local iconType = iconString:sub(1, splitIndex - 1)
        local iconName = iconString:sub(splitIndex + 1)
        return iconType :: IconType, iconName
    end

    -- Icon string is treated as the name if no colon.
    return nil, iconString
end

function Icons.AddIcons(packName: IconType, iconsData: { [string]: IconsMeta })
    if Icons._iconSets[packName] == nil then
        Icons._iconSets[packName] = {
            Icons = {},
            Spritesheets = {},
        }
    end

    for iconName, iconValue in iconsData do
        if type(iconValue) == "number" or (type(iconValue) == "string" and iconValue:match("^rbxassetid://")) then
            local imageId = iconValue
            if type(iconValue) == "number" then
                imageId = "rbxassetid://" .. tostring(iconValue)
            end

            Icons._iconSets[packName].Icons[iconName] = {
                Image = imageId,
                ImageRectSize = Vector2.zero,
                ImageRectPosition = Vector2.zero,
                Parts = nil,
            }
            Icons._iconSets[packName].Spritesheets[imageId] = imageId
        elseif type(iconValue) == "table" then
            if iconValue.Image and iconValue.ImageRectSize and iconValue.ImageRectPosition then
                local imageId = iconValue.Image
                if type(imageId) == "number" then
                    imageId = "rbxassetid://" .. tostring(imageId)
                end

                Icons._iconSets[packName].Icons[iconName] = {
                    Image = imageId,
                    ImageRectSize = iconValue.ImageRectSize,
                    ImageRectPosition = iconValue.ImageRectPosition,
                    Parts = iconValue.Parts,
                }

                if not Icons._iconSets[packName].Spritesheets[imageId] then
                    Icons._iconSets[packName].Spritesheets[imageId] = imageId
                end
            else
                warn("AddIcons: Invalid spritesheet data format for icon '" .. iconName .. "'")
            end
        else
            warn("AddIcons: Unsupported data type for icon '" .. iconName .. "': " .. type(iconValue))
        end
    end
end

function Icons.SetIconsType(iconType: IconType)
    Icons.IconsType = iconType
end

function Icons.Init(newInstanceWrapper: NewInstanceWrapper, iconThemeTag: Color3?)
    Icons.New = newInstanceWrapper
    Icons.IconThemeTag = iconThemeTag

    return Icons
end

function Icons.Icon(icon: string, iconType: IconType): any
    local parsedIconType, parsedIconName = parseIconString(icon)

    iconType = (iconType or parsedIconType or Icons.IconsType) :: IconType

    local iconSet = Icons._iconSets[iconType]
    if iconSet == nil then
        local fetchUrl = ICON_FETCH_URLS[iconType]
        Icons._iconSets[iconType] = (loadstring(game:HttpGetAsync(fetchUrl)) :: () -> IconSetData)()
        iconSet = Icons._iconSets[iconType]
    end

    if iconSet and iconSet.Icons and iconSet.Icons[parsedIconName] then
        return {
            iconSet.Spritesheets[tostring(iconSet.Icons[parsedIconName].Image)],
            iconSet.Icons[parsedIconName] :: any,
        }
    elseif iconSet and iconSet[parsedIconName] and string.find(iconSet[parsedIconName], "rbxassetid://") then
        return {
            iconSet[parsedIconName],
            { ImageRectSize = Vector2.zero, ImageRectPosition = Vector2.zero },
        }
    end
    return nil
end

function Icons.Image(iconConfig: { Icon: string, Type: IconType, colors: { Color3 }, size: UDim2 })
    local Icon = {
        Icon = iconConfig.Icon,
        Type = iconConfig.Type,
        Colors = iconConfig.colors or { (Icons.IconThemeTag or Color3.new(1, 1, 1)), Color3.new(1, 1, 1) },
        Size = iconConfig.size or UDim2.fromOffset(24, 24),

        IconFrame = (nil :: any) :: ImageLabel,
    }

    local Colors: { { Color: Color3?, ThemeTag: any } } = {}

    for i, color in pairs(Icon.Colors) do
        Colors[i] = {
            ThemeTag = type(color) == "string" and color or nil,
            Color = typeof(color) == "Color3" and color or nil,
        }
    end

    local IconLabel = Icons.Icon(Icon.Icon, Icon.Type)
    local isrbxassetid = type(IconLabel) == "string" and IconLabel:find("rbxassetid://")

    if Icons.New then
        local New = Icons.New

        local IconFrame = New("ImageLabel", {
            Size = Icon.Size,
            BackgroundTransparency = 1,
            ImageColor3 = Colors[1].Color or nil,
            ThemeTag = Colors[1].ThemeTag and {
                ImageColor3 = Colors[1].ThemeTag,
            },
            Image = isrbxassetid and IconLabel or IconLabel[1],
            ImageRectSize = if isrbxassetid then nil else IconLabel[2].ImageRectSize,
            ImageRectOffset = if isrbxassetid then nil else IconLabel[2].ImageRectPosition,
        }) :: ImageLabel

        if not isrbxassetid and IconLabel[2].Parts then
            for i, part in IconLabel[2].Parts do
                local IconPartLabel = Icons.Icon(part, Icon.Type)

                local _IconPart = New("ImageLabel", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    ImageColor3 = Colors[1 + i].Color or nil,
                    ThemeTag = Colors[1 + i].ThemeTag and {
                        ImageColor3 = Colors[1 + i].ThemeTag,
                    },
                    Image = IconPartLabel[1],
                    ImageRectSize = IconPartLabel[2].ImageRectSize,
                    ImageRectOffset = IconPartLabel[2].ImageRectPosition,
                    Parent = IconFrame,
                })
            end
        end

        Icon.IconFrame = IconFrame
    else
        local IconFrame = Instance.new("ImageLabel")
        IconFrame.Size = Icon.Size
        IconFrame.BackgroundTransparency = 1
        local color = Colors[1].Color
        if color ~= nil then
            IconFrame.ImageColor3 = color
        end
        IconFrame.Image = isrbxassetid and IconLabel or IconLabel[1]
        if not isrbxassetid then
            IconFrame.ImageRectSize = IconLabel[2].ImageRectSize
            IconFrame.ImageRectOffset = IconLabel[2].ImageRectPosition
        end

        if not isrbxassetid and IconLabel[2].Parts then
            for i, part in IconLabel[2].Parts do
                local IconPartLabel = Icons.Icon(part, Icon.Type)

                local IconPart = Instance.new("ImageLabel")
                IconPart.Size = UDim2.fromScale(1, 1)
                IconPart.BackgroundTransparency = 1
                local color2 = Colors[1 + i].Color
                if color2 ~= nil then
                    IconPart.ImageColor3 = color2
                end
                IconPart.Image = IconPartLabel[1]
                IconPart.ImageRectSize = IconPartLabel[2].ImageRectSize
                IconPart.ImageRectOffset = IconPartLabel[2].ImageRectPosition
                IconPart.Parent = IconFrame
            end
        end

        Icon.IconFrame = IconFrame
    end

    return Icon
end

return Icons
