import express from 'express';
import fs from 'fs';
import https from 'https';
import http from 'http';
import { MongoClient } from 'mongodb';

const app = express();
const httpPort = 3000;
const httpsPort = 3443;

// MongoDB connection
const mongoUri = 'mongodb://admin:admin@10.0.1.221:27017/gameofthrones?authSource=admin';
let db;

// Connect to MongoDB
async function connectToMongoDB() {
  try {
    const client = new MongoClient(mongoUri);
    await client.connect();
    db = client.db('gameofthrones');
    console.log('Connected to MongoDB with admin credentials');
  } catch (error) {
    console.error('MongoDB connection failed:', error.message);
  }
}

// Initialize MongoDB connection
connectToMongoDB();

// Create wizexercise.txt file
try {
  const header = `
═══════════════════════════════════════════════════════════════════
                    🐉 GAME OF THRONES CHARACTER LOG 🐉
═══════════════════════════════════════════════════════════════════
Application started: ${new Date().toISOString()}
Container: Game of Thrones API Server
Purpose: Track all characters fetched from ThronesAPI
═══════════════════════════════════════════════════════════════════

`;
  fs.writeFileSync('wizexercise.txt', header);
  console.log('wizexercise.txt file created with header');
} catch (error) {
  console.log('Error creating wizexercise.txt:', error.message);
}

// Try to load SSL certificates
let httpsOptions = null;

try {
  httpsOptions = {
    key: fs.readFileSync('./ssl/key.pem'),
    cert: fs.readFileSync('./ssl/cert.pem')
  };
  console.log('SSL certificates found');
} catch (error) {
  console.log('No SSL certificates - running HTTP only');
}

// Health check for Docker
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Main page
app.get('/', (req, res) => {
  const html = `
<!DOCTYPE html>
<html>
<head>
    <title>🐉 Game of Thrones API</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            box-sizing: border-box;
        }
        
        body { 
            font-family: 'Georgia', serif; 
            background: linear-gradient(135deg, #2c1810, #8b4513);
            color: #f4f4f4;
            margin: 0;
            padding: 15px;
            min-height: 100vh;
            font-size: 16px;
            line-height: 1.5;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: rgba(0,0,0,0.7);
            padding: 20px;
            border-radius: 15px;
            border: 3px solid #d4af37;
            box-shadow: 0 0 20px rgba(212, 175, 55, 0.3);
            width: 100%;
        }
        
        h1 { 
            text-align: center; 
            color: #d4af37;
            font-size: clamp(1.8rem, 5vw, 2.5rem);
            text-shadow: 2px 2px 4px rgba(0,0,0,0.8);
            margin-bottom: 25px;
            word-wrap: break-word;
        }
        
        .btn {
            display: inline-block;
            background: #d4af37;
            color: #2c1810;
            padding: 12px 20px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: bold;
            font-size: clamp(1rem, 3vw, 1.2rem);
            margin: 8px;
            transition: all 0.3s;
            border: 2px solid #d4af37;
            text-align: center;
            min-width: 140px;
            word-wrap: break-word;
        }
        
        .btn:hover {
            background: transparent;
            color: #d4af37;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(212, 175, 55, 0.4);
        }
        
        .info {
            background: rgba(212, 175, 55, 0.1);
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
            border-left: 4px solid #d4af37;
        }
        
        .info h3 {
            font-size: clamp(1.2rem, 4vw, 1.5rem);
            margin-top: 0;
        }
        
        .info p {
            font-size: clamp(0.9rem, 3vw, 1rem);
            margin: 10px 0;
        }
        
        .center { 
            text-align: center;
            display: flex;
            flex-wrap: wrap;
            justify-content: center;
            gap: 10px;
        }
        
        /* Mobile-specific styles */
        @media (max-width: 768px) {
            body {
                padding: 10px;
            }
            
            .container {
                padding: 15px;
                border-width: 2px;
            }
            
            .btn {
                display: block;
                width: 100%;
                margin: 8px 0;
                padding: 15px;
            }
            
            .center {
                flex-direction: column;
                align-items: center;
            }
            
            .info {
                padding: 12px;
                margin: 12px 0;
            }
        }
        
        @media (max-width: 480px) {
            .container {
                padding: 10px;
                border-radius: 10px;
            }
            
            h1 {
                margin-bottom: 15px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐉 Game of Thrones API 🏰</h1>
        
        <div class="info">
            <h3>🎯 Available Endpoints:</h3>
            <div class="center">
                <a href="/characters" class="btn">🎲 Get Random Character</a>
                <a href="/health" class="btn">💚 Health Check</a>
            </div>
        </div>
        
        <div class="info">
            <h3>⚔️ About:</h3>
            <p>This API serves random Game of Thrones characters from the Seven Kingdoms. Each request fetches a character from the ThronesAPI and logs it to our records.</p>
            <p><strong>Protocol:</strong> ${req.secure ? 'HTTPS 🔒' : 'HTTP 🌐'}</p>
        </div>
    </div>
</body>
</html>`;
  
  res.send(html);
});

// Get random character
app.get('/characters', async (req, res) => {
  try {
    const response = await fetch('https://thronesapi.com/api/v2/Characters');
    const characters = await response.json();
    
    // Pick random character
    const randomChar = characters[Math.floor(Math.random() * characters.length)];
    
    // Create nicely formatted entry for the file
    const timestamp = new Date().toISOString();
    const date = new Date().toLocaleDateString();
    const time = new Date().toLocaleTimeString();
    
    // Save to MongoDB
    try {
      if (db) {
        const characterDoc = {
          fullName: randomChar.fullName,
          title: randomChar.title || 'Unknown',
          family: randomChar.family || 'Unknown',
          firstName: randomChar.firstName || 'Unknown',
          lastName: randomChar.lastName || '',
          imageUrl: randomChar.imageUrl || '',
          fetchedAt: new Date(),
          timestamp: timestamp,
          date: date,
          time: time
        };
        await db.collection('characters').insertOne(characterDoc);
        console.log(`Character saved to MongoDB: ${randomChar.fullName}`);
      } else {
        console.log('MongoDB not connected - character not saved');
      }
    } catch (dbError) {
      console.log('Error saving to MongoDB:', dbError.message);
    }
    
    const entry = `
┌─────────────────────────────────────────────────────────────────┐
│ 📅 ${date} at ${time}                                    │
├─────────────────────────────────────────────────────────────────┤
│ 👑 NAME: ${randomChar.fullName.padEnd(48)} │
│ 🏆 TITLE: ${(randomChar.title || 'Unknown').padEnd(47)} │
│ 🏰 HOUSE: ${(randomChar.family || 'Unknown').padEnd(47)} │
│ 🌍 ORIGIN: ${(randomChar.firstName || 'Unknown').padEnd(46)} │
└─────────────────────────────────────────────────────────────────┘

`;
    
    // Append to wizexercise.txt
    try {
      fs.appendFileSync('wizexercise.txt', entry);
      console.log(`Character logged: ${randomChar.fullName}`);
    } catch (fileError) {
      console.log('Error writing to wizexercise.txt:', fileError.message);
    }
    
    // Return beautiful mobile-responsive HTML response
    const html = `
<!DOCTYPE html>
<html>
<head>
    <title>🐉 ${randomChar.fullName}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            box-sizing: border-box;
        }
        
        body { 
            font-family: 'Georgia', serif; 
            background: linear-gradient(135deg, #2c1810, #8b4513);
            color: #f4f4f4;
            margin: 0;
            padding: 15px;
            min-height: 100vh;
            font-size: 16px;
            line-height: 1.5;
        }
        
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: rgba(0,0,0,0.8);
            padding: 20px;
            border-radius: 15px;
            border: 3px solid #d4af37;
            box-shadow: 0 0 25px rgba(212, 175, 55, 0.4);
            width: 100%;
        }
        
        .character-card {
            text-align: center;
            background: rgba(212, 175, 55, 0.1);
            padding: 20px;
            border-radius: 12px;
            margin: 15px 0;
            border: 2px solid #d4af37;
        }
        
        .character-image {
            width: min(150px, 40vw);
            height: min(150px, 40vw);
            border-radius: 50%;
            border: 4px solid #d4af37;
            margin: 0 auto 15px;
            display: block;
            object-fit: cover;
            max-width: 100%;
        }
        
        h1 { 
            color: #d4af37;
            font-size: clamp(1.5rem, 5vw, 2.2rem);
            text-shadow: 2px 2px 4px rgba(0,0,0,0.8);
            margin-bottom: 10px;
            word-wrap: break-word;
            hyphens: auto;
        }
        
        .title {
            font-size: clamp(1.1rem, 4vw, 1.3rem);
            color: #ffd700;
            font-style: italic;
            margin-bottom: 12px;
            word-wrap: break-word;
        }
        
        .house {
            font-size: clamp(1rem, 3vw, 1.1rem);
            color: #cd853f;
            font-weight: bold;
            word-wrap: break-word;
        }
        
        .btn {
            display: inline-block;
            background: #d4af37;
            color: #2c1810;
            padding: 12px 18px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: bold;
            margin: 8px;
            transition: all 0.3s;
            font-size: clamp(0.9rem, 3vw, 1rem);
            min-width: 120px;
            text-align: center;
        }
        
        .btn:hover {
            background: transparent;
            color: #d4af37;
            border: 2px solid #d4af37;
            transform: translateY(-2px);
        }
        
        .timestamp {
            font-size: clamp(0.8rem, 2.5vw, 0.9rem);
            color: #999;
            margin-top: 15px;
        }
        
        .button-container {
            text-align: center;
            display: flex;
            flex-wrap: wrap;
            justify-content: center;
            gap: 10px;
            margin-top: 20px;
        }
        
        /* Mobile-specific styles */
        @media (max-width: 768px) {
            body {
                padding: 10px;
            }
            
            .container {
                padding: 15px;
                border-width: 2px;
            }
            
            .character-card {
                padding: 15px;
                margin: 10px 0;
            }
            
            .btn {
                display: block;
                width: 100%;
                margin: 8px 0;
                padding: 15px;
            }
            
            .button-container {
                flex-direction: column;
                align-items: center;
            }
        }
        
        @media (max-width: 480px) {
            .container {
                padding: 10px;
                border-radius: 10px;
            }
            
            .character-card {
                padding: 12px;
                border-radius: 8px;
            }
            
            .character-image {
                border-width: 3px;
            }
        }
        
        /* Handle very long names gracefully */
        @media (max-width: 320px) {
            h1 {
                font-size: 1.3rem;
                line-height: 1.3;
            }
            
            .title {
                font-size: 1rem;
            }
            
            .house {
                font-size: 0.95rem;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="character-card">
            ${randomChar.imageUrl ? `<img src="${randomChar.imageUrl}" alt="${randomChar.fullName}" class="character-image" onerror="this.style.display='none'">` : ''}
            
            <h1>👑 ${randomChar.fullName}</h1>
            
            <div class="title">
                🏆 "${randomChar.title || 'Unknown Title'}"
            </div>
            
            <div class="house">
                🏰 House ${randomChar.family || 'Unknown'}
            </div>
            
            <div class="timestamp">
                📅 Generated: ${date} at ${time}
            </div>
        </div>
        
        <div class="button-container">
            <a href="/characters" class="btn">🎲 Another Character</a>
            <a href="/" class="btn">🏠 Home</a>
        </div>
    </div>
</body>
</html>`;
    
    res.send(html);
    
  } catch (error) {
    const errorHtml = `
<!DOCTYPE html>
<html>
<head>
    <title>⚠️ Error</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { box-sizing: border-box; }
        body { 
            font-family: Georgia, serif; 
            background: #2c1810; 
            color: #f4f4f4; 
            text-align: center; 
            padding: 20px;
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error { 
            background: rgba(139, 0, 0, 0.3); 
            padding: 25px; 
            border-radius: 10px; 
            border: 2px solid #dc143c;
            max-width: 500px;
            width: 100%;
        }
        .error h1 {
            font-size: clamp(1.2rem, 4vw, 1.8rem);
            margin-bottom: 15px;
        }
        .error p {
            font-size: clamp(0.9rem, 3vw, 1rem);
            margin: 10px 0;
        }
        .error a {
            color: #d4af37;
            font-size: clamp(0.9rem, 3vw, 1rem);
            text-decoration: none;
            display: inline-block;
            margin-top: 10px;
        }
        @media (max-width: 480px) {
            .error { padding: 15px; }
        }
    </style>
</head>
<body>
    <div class="error">
        <h1>⚠️ The Seven Kingdoms Are Unreachable</h1>
        <p>Failed to fetch character data from the realm.</p>
        <a href="/">🏠 Return to Safety</a>
    </div>
</body>
</html>`;
    res.status(500).send(errorHtml);
  }
});

// Start servers
http.createServer(app).listen(httpPort, () => {
  console.log(`HTTP server running on port ${httpPort}`);
});

if (httpsOptions) {
  https.createServer(httpsOptions, app).listen(httpsPort, () => {
    console.log(`HTTPS server running on port ${httpsPort}`);
  });
}