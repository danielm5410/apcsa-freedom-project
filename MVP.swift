import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    let player = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 50))
    var cursorPosition: CGPoint = .zero
    var enemies = [SKSpriteNode]()
    var movingLeft = false
    var movingRight = false
    var movingUp = false
    var movingDown = false
    var shootDirection: CGPoint = .zero
    var gameOverLabel: SKLabelNode?
    var bullets = [SKSpriteNode]()
    let enemyCategory: UInt32 = 0x1 << 0
        let bulletCategory: UInt32 = 0x1 << 1

    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupPlayer()
        spawnEnemies()
        physicsWorld.contactDelegate = self
    }
    func setupPhysicsBody(for enemy: SKSpriteNode) {
          enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
          enemy.physicsBody?.categoryBitMask = enemyCategory
          enemy.physicsBody?.collisionBitMask = 0 // No collision
          enemy.physicsBody?.contactTestBitMask = bulletCategory
      }


    func setupPlayer() {
        player.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(player)
    }

    func spawnEnemies() {
        let spawnAction = SKAction.run {
            let enemy = SKSpriteNode(color: .red, size: CGSize(width: 30, height: 30))
            enemy.position = CGPoint(x: CGFloat.random(in: 0..<self.size.width), y: self.size.height)
            self.addChild(enemy)
            self.enemies.append(enemy)
        }
        let waitAction = SKAction.wait(forDuration: 1.5)
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }

    func fireBullet() {
        let bullet = SKSpriteNode(color: .green, size: CGSize(width: 4, height: 10))
        bullet.position = player.position
        setupPhysicsBody(for: bullet)

        let direction = shootDirection.normalized()
        let shootAmount = direction * 1000
        let realDest = shootAmount + bullet.position
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([actionMove, actionRemove]))

        addChild(bullet)
        bullets.append(bullet)
    }
    func didBegin(_ contact: SKPhysicsContact) {
            if (contact.bodyA.categoryBitMask == enemyCategory && contact.bodyB.categoryBitMask == bulletCategory) ||
               (contact.bodyB.categoryBitMask == enemyCategory && contact.bodyA.categoryBitMask == bulletCategory) {
                // Remove the enemy and the bullet from the scene
                if let enemyNode = contact.bodyA.node as? SKSpriteNode {
                    enemyNode.removeFromParent()
                    if let index = enemies.firstIndex(of: enemyNode) {
                        enemies.remove(at: index)
                    }
                }
                if let bulletNode = contact.bodyB.node as? SKSpriteNode {
                    bulletNode.removeFromParent()
                    if let index = bullets.firstIndex(of: bulletNode) {
                        bullets.remove(at: index)
                    }
                }
            }
        }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 49: // Space bar
            fireBullet()
        case 123: // Left arrow
            movingLeft = true
        case 124: // Right arrow
            movingRight = true
        case 125: // Down arrow
            movingDown = true
        case 126: // Up arrow
            movingUp = true
        case 3: // F key
            if isPaused {
                restartGame()
            }
        default:
            break
        }
        updateShootDirection()
    }

    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 123: // Left arrow
            movingLeft = false
        case 124: // Right arrow
            movingRight = false
        case 125: // Down arrow
            movingDown = false
        case 126: // Up arrow
            movingUp = false
        default:
            break
        }
        updateShootDirection()
    }

    override func mouseMoved(with event: NSEvent) {
        cursorPosition = event.location(in: self)
        updateShootDirection()
    }

    func updateShootDirection() {
        var dx: CGFloat = 0
        var dy: CGFloat = 0

        if movingLeft {
            dx -= 1
        }
        if movingRight {
            dx += 1
        }
        if movingDown {
            dy -= 1
        }
        if movingUp {
            dy += 1
        }

        shootDirection = CGPoint(x: dx, y: dy)
    }

    override func update(_ currentTime: TimeInterval) {
        movePlayer()
        moveEnemies()
        checkCollisions()
    }

    func movePlayer() {
        let moveAmount: CGFloat = 5
        let minX = player.size.width / 2
        let maxX = size.width - player.size.width / 2
        let minY = player.size.height / 2
        let maxY = size.height - player.size.height / 2

        if movingLeft {
            player.position.x = max(player.position.x - moveAmount, minX)
        }
        if movingRight {
            player.position.x = min(player.position.x + moveAmount, maxX)
        }
        if movingUp {
            player.position.y = min(player.position.y + moveAmount, maxY)
        }
        if movingDown {
            player.position.y = max(player.position.y - moveAmount, minY)
        }
    }

    func moveEnemies() {
        let minX = player.size.width / 2
        let maxX = size.width - player.size.width / 2
        let minY = player.size.height / 2
        let maxY = size.height - player.size.height / 2

        for enemy in enemies {
            let offset = player.position - enemy.position
            let direction = offset.normalized()
            let moveAmount = direction * 1.5 // Slower movement
            
            var newPosition = enemy.position + moveAmount
            newPosition.x = min(max(newPosition.x, minX), maxX)
            newPosition.y = min(max(newPosition.y, minY), maxY)
            
            enemy.position = newPosition
        }
    }

    

    func checkCollisions() {
        for enemy in enemies {
            for bullet in bullets {
                if enemy.intersects(bullet) {
                    // Remove the bullet from the scene
                    bullet.removeFromParent()

                    // Remove the bullet from the bullets array
                    if let index = bullets.firstIndex(of: bullet) {
                        bullets.remove(at: index)
                    }

                    // Remove the enemy from the scene
                    enemy.removeFromParent()

                    // Remove the enemy from the enemies array
                    if let index = enemies.firstIndex(of: enemy) {
                        enemies.remove(at: index)
                    }

                    // Break out of the bullet loop (no need to check more bullets for this enemy)
                    break
                }
            }

            // Check for collisions with the player
            if player.intersects(enemy) {
                gameOver()
                return
            }
        }
    }

    func gameOver() {
        // Display "Game Over" label
        gameOverLabel = SKLabelNode(text: "Game Over. Press F to restart.")
        gameOverLabel?.fontColor = .white
        gameOverLabel?.fontSize = 40
        gameOverLabel?.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(gameOverLabel!)
        
        // Pause the scene
        isPaused = true
    }

    func restartGame() {
        // Remove game over label
        gameOverLabel?.removeFromParent()
        
        // Reset player position
        player.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Remove all enemies
        for enemy in enemies {
            enemy.removeFromParent()
        }
        enemies.removeAll()
        
        // Unpause the scene
        isPaused = false
    }
}

extension CGPoint {
    func normalized() -> CGPoint {
        let length = sqrt(x*x + y*y)
        return self / length
    }

    static func +(left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }

    static func -(left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }

    static func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * scalar, y: point.y * scalar)
    }

    static func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x / scalar, y: point.y / scalar)
    }
}
