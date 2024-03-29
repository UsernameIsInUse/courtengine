function NewCharLocationEvent(name, location)
    local self = {}
    self.name = name
    self.location = location

    self.update = function (self, scene, dt)
        scene.characterLocations[self.location] = scene.characters[self.name]

        return false
    end

    return self
end

function NewPoseEvent(name, pose)
    local self = {}
    self.name = name
    self.pose = pose

    self.update = function (self, scene, dt)
        scene.characters[self.name].frame = self.pose

        return false
    end

    return self
end

function NewAnimationEvent(name, animation, speed)
    local self = {}
    self.name = name
    self.animation = animation
    self.timer = 0
    self.animIndex = 1

    if speed == nil then
        speed = 10
    end
    self.speed = speed

    self.update = function (self, scene, dt)
        scene.canShowCharacter = false
        scene.canShowCourtRecord = false
        scene.textHidden = true

        self.timer = self.timer + dt*self.speed
        self.animIndex = math.max(math.floor(self.timer +0.5), 1)

        local animation = scene.characters[self.name].animations[self.animation]
        if self.animIndex <= #animation.anim then
            return true
        end

        scene.canShowCharacter = true
        return false
    end

    self.characterDraw = function (self, scene)
        local animation = scene.characters[self.name].animations[self.animation]
        love.graphics.draw(animation.source, animation.anim[self.animIndex])
    end

    return self
end

function NewCutToEvent(cutTo)
    local self = {}
    self.cutTo = cutTo

    self.update = function (self, scene, dt)
        scene.location = self.cutTo
        return false
    end

    return self
end

function NewSpeakEvent(who, text, locorlit)
    local self = {}
    self.text = text
    self.textScroll = 1
    self.wasPressing = true
    self.who = who
    self.locorlit = locorlit

    self.color = {1,1,1}
    self.animates = true
    self.speaks = true

    self.update = function (self, scene, dt)
        scene.fullText = self.text

        local lastScroll = self.textScroll
        self.textScroll = math.min(self.textScroll + dt*TextScrollSpeed, #self.text)

        if self.textScroll < #self.text then
            scene.characterTalking = self.animates
        end

        if self.locorlit == "literal" then
            scene.textTalker = self.who
        else
            scene.textTalker = scene.characterLocations[self.who].name
        end

        if self.textScroll > lastScroll and self.speaks then
            if scene.characters[scene.textTalker].gender == "MALE" then
                Sounds.MALETALK:play()
            else
                Sounds.FEMALETALK:play()
            end
        end

        scene.textColor = self.color
        scene.text = string.sub(self.text, 1, math.floor(self.textScroll))

        local pressing = love.keyboard.isDown("x")
        if pressing and not self.wasPressing and self.textScroll >= #self.text then
            return false
        end
        self.wasPressing = pressing

        return true
    end

    return self
end

function NewThinkEvent(who, text, locorlit)
    local self = NewSpeakEvent(who, text, locorlit)
    self.color = {0, 0.75, 1}
    self.animates = false
    self.speaks = false

    return self
end

function NewTypeWriterEvent(text)
    local self = {}
    self.text = text
    self.textScroll = 1
    self.wasPressing = true

    self.update = function (self, scene, dt)
        local lastScroll = self.textScroll
        self.textScroll = math.min(self.textScroll + dt*TextScrollSpeed, #self.text)

        if self.textScroll > lastScroll then
            Sounds.TYPEWRITER:play()
        end

        scene.fullText = self.text
        scene.textCentered = true
        scene.textColor = {0,1,0}
        scene.text = string.sub(self.text, 1, math.floor(self.textScroll))
        scene.textTalker = ""
        scene.textBoxSprite = AnonTextBoxSprite

        local pressing = love.keyboard.isDown("x")
        if pressing and not self.wasPressing and self.textScroll >= #self.text then
            return false
        end
        self.wasPressing = pressing

        return true
    end

    self.draw = function (self, scene)
        love.graphics.setColor(0,0,0)
        love.graphics.rectangle('fill', 0,0,GraphicsWidth(),GraphicsHeight())
    end

    return self
end

function NewAddToCourtRecordAnimationEvent(text, evidence)
    local self = {}
    self.text = text
    self.textScroll = 1
    self.evidence = evidence
    self.wasPressing = true

    self.update = function (self, scene, dt)
        self.textScroll = math.min(self.textScroll + dt*TextScrollSpeed, #self.text)
        scene.fullText = self.text
        scene.textCentered = true
        scene.textColor = {0,0.2,1}
        scene.text = string.sub(self.text, 1, math.floor(self.textScroll))
        scene.textTalker = ""
        scene.textBoxSprite = AnonTextBoxSprite

        local pressing = love.keyboard.isDown("x")
        if pressing and not self.wasPressing and self.textScroll >= #self.text then
            return false
        end
        self.wasPressing = pressing

        return true
    end

    self.draw = function (self, scene)
        love.graphics.setColor(1,1,1)
        love.graphics.draw(scene.evidence[self.evidence].sprite, 16,16)
    end

    return self
end


function NewObjectionEvent(who)
    local self = {}
    self.timer = 0
    self.x,self.y = 0,0
    self.who = who

    self.update = function (self, scene, dt)
        scene.textHidden = true
        scene.characters[self.who].sounds.objection:play()
        self.timer = self.timer + dt
        self.x = self.x + love.math.random()*choose{1,-1}*2
        self.y = self.y + love.math.random()*choose{1,-1}*2

        return self.timer < 0.5
    end

    self.draw = function (self, scene)
        love.graphics.draw(ObjectionSprite, self.x,self.y)
    end

    return self
end

function NewHoldItEvent(who)
    local self = {}
    self.timer = 0
    self.x,self.y = 0,0
    self.who = who

    self.update = function (self, scene, dt)
        scene.textHidden = true
        scene.characters[self.who].sounds.holdit:play()
        self.timer = self.timer + dt
        self.x = self.x + love.math.random()*choose{1,-1}*2
        self.y = self.y + love.math.random()*choose{1,-1}*2

        return self.timer < 0.5
    end

    self.draw = function (self, scene)
        love.graphics.draw(HoldItSprite, self.x,self.y)
    end

    return self
end

function NewPlayMusicEvent(music)
    local self = {}
    self.music = music

    self.update = function (self, scene, dt)
        for i,v in pairs(Music) do
            v:stop()
        end

        Music[self.music]:play()

        return false
    end

    return self
end

function NewCourtRecordAddEvent(evidence)
    local self = {}
    self.evidence = evidence

    self.update = function (self, scene, dt)
        table.insert(scene.courtRecord, scene.evidence[self.evidence])
        return false
    end

    return self
end

function NewCrossExaminationEvent(queue)
    local self = {}
    self.queue = queue
    self.textScroll = 1
    self.textIndex = 2
    self.wasPressing = true
    self.who = queue[1]
    self.timer = 0
    self.animationTime = 1.5

    self.advanceText = function (self)
        if self.textIndex == 2 then
            self.textIndex = 4
        else
            self.textIndex = self.textIndex + 4
        end

        self.textScroll = 1
        self.wasPressing = true

        if self.textIndex > #self.queue then
            self.textIndex = 4
        end
    end

    self.update = function (self, scene, dt)
        self.timer = self.timer + dt

        local text = self.queue[self.textIndex]

        local lastScroll = self.textScroll
        self.textScroll = math.min(self.textScroll + dt*TextScrollSpeed, #text)

        if self.textIndex == 2 then
            scene.textColor = {1,0.5,0}
            scene.textCentered = true
        else
            scene.characters[self.who].frame = self.queue[self.textIndex+3]
            if self.textScroll < #text then
                scene.characterTalking = true
            end

            scene.textColor = {0,1,0.25}
        end
        scene.text = string.sub(text, 1, math.floor(self.textScroll))
        scene.fullText = text
        scene.textTalker = self.who

        if self.textScroll > lastScroll then
            if scene.characters[scene.textTalker].gender == "MALE" then
                Sounds.MALETALK:play()
            else
                Sounds.FEMALETALK:play()
            end
        end


        local canAdvance = self.textScroll >= #text and self.timer > self.animationTime

        local pressing = love.keyboard.isDown("x")
        if pressing 
        and not self.wasPressing 
        and canAdvance then
            self:advanceText()
        end
        self.wasPressing = pressing

        if love.keyboard.isDown("c")
        and canAdvance then
            scene:runDefinition(self.queue[self.textIndex+1])
            self:advanceText()
        end

        if love.keyboard.isDown("up") 
        and scene.showCourtRecord then
            scene.showCourtRecord = false

            if scene.courtRecord[scene.courtRecordIndex].name == self.queue[self.textIndex+2] then
                return false
            else
                scene:runDefinition(self.queue[3])
                self:advanceText()
            end
        end

        return true
    end

    self.draw = function (self, scene)
        if self.timer < self.animationTime then
            love.graphics.draw(CrossExaminationSprite, GraphicsWidth()/2,GraphicsHeight()/2 -24, 0, 1,1, CrossExaminationSprite:getWidth()/2,CrossExaminationSprite:getHeight()/2)
        else
            love.graphics.setColor(1,1,1)
            for i=1, scene.penalties do
                love.graphics.draw(PenaltySprite, (i-1)*12 +2,2)
            end
        end
    end

    return self
end

function NewIssuePenaltyEvent()
    local self = {}
    
    self.update = function (self, scene, dt)
        scene.penalties = scene.penalties - 1

        if scene.penalties <= 0 then
            scene:runDefinition("TRIAL_FAIL")
        end

        return false
    end

    return self
end

function NewGameOverEvent()
    local self = {}

    self.update = function (self, scene, dt)
        love.event.push("quit")
        return false
    end

    return self
end

function NewExecuteDefinitionEvent(def)
    local self = {}
    self.def = def
    self.hasRun = false

    self.update = function (self, scene, dt)
        if not self.hasRun then
            self.hasRun = true
            scene:runDefinition(self.def)
        end

        return false
    end

    return self
end

function NewClearExecuteDefinitionEvent(def)
    local self = {}
    self.def = def
    self.hasRun = false

    self.update = function (self, scene, dt)
        if not self.hasRun then
            self.hasRun = true
            scene:runDefinition(self.def, 2)
        end

        return false
    end

    return self
end

function NewChoiceEvent(options)
    local self = {}
    self.select = 1
    self.options = options

    self.wasPressingUp = false
    self.wasPressingDown = false
    self.wasPressingX = true

    self.update = function (self, scene, dt)
        local pressingUp = love.keyboard.isDown("up")
        local pressingDown = love.keyboard.isDown("down")

        if not self.wasPressingUp and pressingUp then
            self.select = self.select - 2

            if self.select < 1 then
                self.select = #self.options -1
            end
        end

        if not self.wasPressingDown and pressingDown then
            self.select = self.select + 2 

            if self.select > #self.options -1 then
                self.select = 1
            end
        end

        self.wasPressingUp = pressingUp
        self.wasPressingDown = pressingDown

        local pressingX = love.keyboard.isDown("x")

        if pressingX and not self.wasPressingX then
            if self.options[self.select+1] == "0" then
                return false
            else
                scene:runDefinition(self.options[self.select+1])
            end
        end

        self.wasPressingX = pressingX

        return true
    end

    self.draw = function (self, scene)
        for i=1, #self.options, 2 do
            love.graphics.setColor(0.2,0.2,0.2)
            if self.select == i then
                love.graphics.setColor(0.8,0,0.2)
            end
            love.graphics.rectangle("fill", 146,30+(i-1)*16 -4, GraphicsWidth(),28)
            love.graphics.setColor(1,1,1)
            love.graphics.print(self.options[i], 150,30+(i-1)*16)
        end
    end

    return self
end

function NewInvestigationMenuEvent(options)
    local self = NewChoiceEvent(options)

    self.parentUpdate = self.update
    self.update = function (self, scene, dt)
        scene.textHidden = true
        return self.parentUpdate(self, scene, dt)
    end

    return self
end

function NewSceneEndEvent()
    local self = {}

    self.update = function (self, scene, dt)
        NextScene()
        return false
    end

    return self
end

function NewExamineEvent(examinables)
    local self = {}
    self.x = GraphicsWidth()/2
    self.y = GraphicsHeight()/2
    self.examinables = examinables
    self.wasPressingX = false

    self.update = function (self, scene, dt)
        scene.textHidden = true
        scene.canShowCourtRecord = false
        scene.canShowCharacter = false

        local moveSpeed = 2*(dt*60)
        if love.keyboard.isDown("right") then
            self.x = self.x + moveSpeed
        end
        if love.keyboard.isDown("left") then
            self.x = self.x - moveSpeed
        end
        if love.keyboard.isDown("up") then
            self.y = self.y - moveSpeed
        end
        if love.keyboard.isDown("down") then
            self.y = self.y + moveSpeed
        end

        if love.keyboard.isDown("z") then
            return false
        end

        local pressingX = love.keyboard.isDown("x")
        if not self.wasPressingX and pressingX then
            for i=1, #self.examinables, 5 do
                if  self.x >= tonumber(self.examinables[i])
                and self.y >= tonumber(self.examinables[i+1])
                and self.x <= tonumber(self.examinables[i+2])
                and self.y <= tonumber(self.examinables[i+3]) then
                    --print(self.examinables[i+4])
                    scene:runDefinition(self.examinables[i+4])
                end
            end
        end
        self.wasPressingX = pressingX

        self.x = math.max(math.min(self.x, GraphicsWidth()), 0)
        self.y = math.max(math.min(self.y, GraphicsHeight()), 0)

        return true
    end

    self.draw = function (self, scene)
        love.graphics.setColor(0,0.2,1, 1)

        for i=1, #self.examinables, 5 do
            if  self.x >= tonumber(self.examinables[i])
            and self.y >= tonumber(self.examinables[i+1])
            and self.x <= tonumber(self.examinables[i+2])
            and self.y <= tonumber(self.examinables[i+3]) then
                love.graphics.setColor(1,1,0)
            end
        end

        local rad = 4
        love.graphics.rectangle("line", self.x-rad,self.y-rad,rad*2,rad*2)
        love.graphics.line(self.x,self.y-rad,self.x,self.y+rad)
        love.graphics.line(self.x-rad,self.y,self.x+rad,self.y)
    end

    return self
end

function NewWideShotEvent()
    local self = {}
    self.timer = 0
    self.hasPlayed = false
    self.sources = {}
    self.headAnim = 1
    self.frameCounter = 0

    self.update = function (self, scene, dt)
        self.timer = self.timer + dt
        self.frameCounter = self.frameCounter + dt

        while self.frameCounter >= 2/15 do
            self.frameCounter = self.frameCounter - 2/15
            self.headAnim = self.headAnim + 1
            if self.headAnim > 4 then
                self.headAnim = 1
            end
        end

        scene.textHidden = true

        if not self.hasPlayed then
            --self.sources = love.audio.pause()
            Sounds.MUTTER:play()
            self.hasPlayed = true
        end

        scene.textHidden = true
        scene.canShowCourtRecord = false

        if self.timer >= 2 then
            Sounds.MUTTER:stop()
            for i,v in pairs(self.sources) do
                v:play()
            end
            return false
        end

        return true
    end

    self.draw = function (self, scene)
        love.graphics.draw(WideShotSprite)
        love.graphics.draw(TalkingHeadAnimation[self.headAnim])

        for i,v in pairs(scene.characters) do
            love.graphics.draw(v.wideshot.source)
        end
    end

    return self
end

function NewGavelEvent()
    local self = {}
    self.timer = 0
    self.index = 1
    self.hasPlayed = false
    self.muted = false
    self.sources = {}

    self.update = function (self, scene, dt)
        self.timer = self.timer + dt
        scene.textHidden = true
        scene.canShowCourtRecord = false

        if not self.muted then
            self.muted = true
            --self.sources = love.audio.pause()
        end

        if self.timer > 0.2 then
            self.index = 2
        end

        if self.timer > 0.5 then
            self.index = 3

            if not self.hasPlayed then
                self.hasPlayed = true
                Sounds.GAVEL:play()
            end
        end

        if self.timer >= 1 then
            for i,v in pairs(self.sources) do
                v:play()
            end
            return false
        end
        return true
    end

    self.draw = function (self, scene)
        local spr = GavelAnimation[self.index]
        love.graphics.draw(spr, 0,0, 0, GraphicsWidth()/spr:getWidth(),GraphicsHeight()/spr:getHeight())
    end
    return self
end

function NewStopMusicEvent()
    local self = {}

    self.update = function (self, scene, dt)
        for i,v in pairs(Music) do
            v:stop()
        end

        return false
    end

    return self
end

function NewFadeToBlackEvent()
    local self = {}
    self.timer = 0

    self.update = function (self, scene, dt)
        scene.textHidden = true
        scene.canShowCourtRecord = false

        local lastTimer = self.timer 
        self.timer = self.timer + dt

        return self.timer <= 1 and lastTimer <= 1
    end

    self.draw = function (self, scene)
        love.graphics.setColor(0,0,0, self.timer)
        love.graphics.rectangle("fill", 0,0, GraphicsWidth(),GraphicsHeight())
    end

    return self
end