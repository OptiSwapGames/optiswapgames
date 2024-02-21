import React, { useState, useEffect, useRef } from 'react';
import { bulldogblast } from "../../declarations/bulldogblast"
import '../assets/bdb.css';

import green01 from '../assets/ships/green01.png';
import orange01 from '../assets/ships/orange01.png';
import red01 from '../assets/ships/red01.png';
import violet01 from '../assets/ships/violet01.png';
import GREEN from '../assets/tokens/GREEN.svg';
import ORANGE from '../assets/tokens/ORANGE.svg';
import RED from '../assets/tokens/RED.svg';
import VIOLET from '../assets/tokens/VIOLET.svg';
import green from "../assets/characters/green.png";
import orange from "../assets/characters/orange.png";
import red from "../assets/characters/red.png";
import violet from "../assets/characters/violet.png";

const assets = {"ships": { 1: green01, 2: orange01, 3: red01, 4: violet01 },
                "characters": { 1: green, 2: orange, 3: red, 4: violet },
                "bombs": { 1: GREEN, 2: ORANGE, 3: RED, 4: VIOLET }
         };

const BulldogBlast = ( { gameID, playerID, handleGameEnd }) => {

    let isDragging = false;
    let startPoint = {x:0, y:0};
    let lastTimestamp = 0;
    let tick = 0;
    let gos = {}
    let [names, setNames] = useState(["loading...", "loading...", "loading...", "loading..."])
    let [scores, setScores] = useState([0,0,0,0])

    const svgRef = useRef(null);
    let frames = 0
    let deltaTime = 0;


    const resizeSvg = () => {
      const { innerWidth, innerHeight } = window;
      const aspectRatio = 800 / 600;
      const svgElement = svgRef.current;

      const windowRatio = innerWidth / innerHeight;
      if (windowRatio > aspectRatio) {
        // Fit to height
        svgElement.setAttribute('height', innerHeight);
        svgElement.setAttribute('width', innerHeight * aspectRatio);
      } else {
        // Fit to width
        svgElement.setAttribute('width', innerWidth);
        svgElement.setAttribute('height', innerWidth / aspectRatio);
      }
    };

    useEffect(() => {
      window.addEventListener('resize', resizeSvg);
      resizeSvg(); // Initial resize
      return () => {
        window.removeEventListener('resize', resizeSvg);
      };
    }, []);

    //Draw stars
    useEffect(() => {
      const svgElement = svgRef.current;
      const numStars = 50;
      for (let i = 0; i < numStars; i++) {
        const star = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        star.setAttribute('cx', Math.random() * 800); // Random x-coordinate
        star.setAttribute('cy', Math.random() * 600); // Random y-coordinate
        star.setAttribute('r', Math.random() * 2 + 0.5); // Random radius between 0.5 and 2
        star.setAttribute('fill', 'white'); // Star color
        svgElement.appendChild(star);
      }
      return () => {
        while (svgElement.firstChild) {
          svgElement.removeChild(svgElement.firstChild);
        }
      };
    }, []); 

    const rotation = function(velocity, defaultDegrees) {
         let degrees = (velocity.x === 0 && velocity.y === 0) ? defaultDegrees
            : Math.atan2(velocity.y, velocity.x) * (180 / Math.PI) + 90;
         return degrees;
    };

    function createShip(ship) {
      const svgElement = svgRef.current;
      let {id, physicalPresence } = ship;
      let { position } = physicalPresence.inertialState;

      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('width', '40');
      svg.setAttribute('height', '50'); 

      const background = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
      background.setAttribute('width', '40');
      background.setAttribute('height', '5'); 
      background.setAttribute('fill', 'red'); 
      svg.appendChild(background);
      
      const healthBar = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
      healthBar.setAttribute('width', 40 * ship.health.toString() / 100);
      healthBar.setAttribute('height', '5'); 
      healthBar.setAttribute('fill', 'green'); 
      svg.appendChild(healthBar)

      const img = document.createElementNS('http://www.w3.org/2000/svg', 'image');
      img.setAttribute('href', assets.ships[id]);
      img.setAttribute('width', '40');
      img.setAttribute('height', '40');
      svg.appendChild(img);

      if (ship.health == 0) { 
          svg.setAttribute('visibility', 'hidden');
      }

      const startRotations = { 1: 135, 2: 225, 3: 45, 4: 315};
      ship.defaultDegrees = startRotations[ship.id];

      svgElement.appendChild(svg);

      ship["svg"] = svg;
      ship["img"] = img;
      ship["healthbar"] = healthBar
      return ship;
    }

    function createBomb(bomb) {
      const svgElement = svgRef.current;
      let {id, physicalPresence, fill, rotate} = bomb;
      let { inertialState } = physicalPresence;
      let {position} = inertialState;
      window.is = inertialState;

      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('width', '40');
      svg.setAttribute('height', '50');

      const img = document.createElementNS('http://www.w3.org/2000/svg', 'image');
      img.setAttribute('href', assets.bombs[bomb.launchedBy]);
      img.setAttribute('width', '50');
      img.setAttribute('height', '50'); 
      svg.appendChild(img);

      svgElement.appendChild(svg);
      bomb["svg"] = svg;
      bomb["img"] = img;
      return bomb;
    }

    function distance(p1, p2) {
      return Math.sqrt((p2.x - p1.x)**2 + (p2.y - p1.y)**2)
    }

    function allShips() {
      return Object.values(gos).filter(x => goType(x) === "Ship")
    }

    function createExplosion(launchedBy, position) {
      const explosion = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      explosion.setAttribute('cx', position.x)
      explosion.setAttribute('cy', position.y)
      explosion.setAttribute('r', '100')
      const explosionColors = {1: "green", 2: "orange", 3: "red", 4: "purple"};
      let color = explosionColors[launchedBy] ? explosionColors[launchedBy] : "white";
      explosion.setAttribute('fill', color);
      explosion.setAttribute('class', "explosion")
      document.getElementById('game-svg').appendChild(explosion);
    }

    function blowUp(bomb) {
      let { physicalPresence, launchedBy, power, blastRadius } = bomb;
      let {position} = physicalPresence.inertialState;
      createExplosion(launchedBy, position);
      let newScores = []
      allShips().forEach(ship => {
        let health = ship.health.toString()
        newScores.push(ship.score.toString());
        ship.healthbar.setAttribute('width', 40 * health / 100);
        if (health == 0 && ship.svg.getAttribute('visibility') !== "hidden" ) {
          ship.svg.setAttribute('visibility', 'hidden');
          //createExplosion(ship.physicalPresence.inertialState.position)
        }
      })
      setScores(newScores)

    }

    var goType = (go) => Object.keys(go.t)[0]

    var create = (go) => {
      go.defaultDegrees = 0;
      switch (goType(go)) {
        case "Ship":
          return createShip(go)
        case "Bomb":
          return createBomb(go)
      }
    }

    var removeObject = (goid) => {
      let go = gos[goid]
      if (goType(go) == "Bomb") {
        blowUp(go)
      }
      go.svg.remove();
      delete gos[goid]
    }

    var refresh = async() => {
      if (!gameID) return;
      const canisterTick = await bulldogblast.getTick(gameID);
      if (canisterTick == tick) return;

      const gameStatus = await bulldogblast.gameStatus(gameID)
      if ("Complete" in gameStatus) {
        handleGameEnd()
      }
      tick = canisterTick;
      const result = await bulldogblast.getGameView(gameID);
      let natData = {}
      result["dataKeys"].forEach((k,i) => {
        const [id, type, key] = k.split(".")
        const value = result["dataValues"][i]
        if (!natData[id]) { natData[id] = {}}
        natData[id][key] = value 
      })

      //Update or create local objects
      await Promise.all(result["objects"].map(async (x) => {
        let localGo = { ...(gos[x.id] || {}), ...x, ...(natData[x.id] || {}) };
        gos[x.id] = gos[x.id] ? localGo : create(localGo);
      }));

      Object.keys(gos).forEach(goid => {
        let incomingIds = result["objects"].map(x => x.id.toString());
        if (!(incomingIds.includes(goid))) {
          removeObject(goid)
        }
      })
    
        // frames = 1000
        lastTimestamp = 0
        moveObjects()
    };


    const fetchScores = async () => {
      const scores = await bulldogblast.getScores(gameID)
      setNames(scores.map(x => x['name']))
    }

    useEffect(() => {
      refresh()
      fetchScores()
      const intervalId = setInterval(refresh, 1000);
      return () => {
        clearInterval(intervalId);
      };
    }, []);

    let vectorAdd = (v1, v2) => {
      v1.x += v2.x;
      v1.y += v2.y;
    }

    function moveObjects() {
/*      if (frames <= 0) {
        return
      }*/

/*      let timestamp = Date.now();
      if (lastTimestamp !== 0) {
          deltaTime = (timestamp - lastTimestamp);
      } else {
          deltaTime = 1
      }
      frames = frames - deltaTime;
      deltaTime = deltaTime / 10 //100 units of game time = 1 second
      lastTimestamp = timestamp;*/
      deltaTime = 100

      Object.values(gos).forEach((go) => {
        let {position, velocity, acceleration} = go.physicalPresence.inertialState
        vectorAdd(velocity, {x: acceleration.x * deltaTime, y: acceleration.y * deltaTime})
        let interpolatedPosition = {
          x: ((position.x + velocity.x * deltaTime) + 800) % 800,
          y: ((position.y + velocity.y * deltaTime) + 600) % 600
        };
        go.physicalPresence.inertialState.position = interpolatedPosition;
        let degrees = rotation(velocity, go.defaultDegrees);
        go.svg.setAttribute('transform', `translate(${interpolatedPosition.x - 20} ${interpolatedPosition.y - 25})`);
        if (go.img) {
          go.img.setAttribute('transform', `rotate(${degrees} 20 20)`);
        }

      })
      //requestAnimationFrame(moveObjects);
    }

    //mousedown
    useEffect(() => {
      const svgElement = svgRef.current;

      const handleMouseDown = event => {
        isDragging = true;
        const svgRect = svgElement.getBoundingClientRect();
        const svgPoint = svgElement.createSVGPoint();
        svgPoint.x = event.clientX;
        svgPoint.y = event.clientY;
        startPoint =svgPoint.matrixTransform(svgElement.getScreenCTM().inverse());
      };

      svgElement.addEventListener('mousedown', handleMouseDown);

      return () => {
        svgElement.removeEventListener('mousedown', handleMouseDown);
      };
    }, []);    

    //mouseup
    useEffect(() => {
      const svgElement = svgRef.current;
      const handleMouseUp = async event => {
        if (!isDragging) return;
        const svgRect = svgElement.getBoundingClientRect();
        const svgPoint = svgElement.createSVGPoint();
        svgPoint.x = event.clientX;
        svgPoint.y = event.clientY;
        const endPoint = svgPoint.matrixTransform(svgElement.getScreenCTM().inverse());
        const dx = endPoint.x - startPoint.x;
        const dy = endPoint.y - startPoint.y;
        const swipeLength = Math.sqrt(dx ** 2 + dy ** 2);

        if (swipeLength > 10) {
          const normalizedVector = { x: dx / swipeLength, y: dy / swipeLength };
          const result = await bulldogblast.input(gameID, playerID, {
            commandType: { Thrust: null },
            vector: normalizedVector,
            player: playerID
          });
        } else {
          const targetPoint = { x: endPoint.x, y: endPoint.y };
          const result = await bulldogblast.input(gameID, playerID, {
            commandType: { Fire: null },
            vector: targetPoint,
            player: playerID
          });
        }
        isDragging = false;
      };

      svgElement.addEventListener('mouseup', handleMouseUp);

      return () => {
        svgElement.removeEventListener('mouseup', handleMouseUp);
      };
    }, []);

    useEffect(() => {
      const svgElement = svgRef.current;
      const handleMouseLeave = () => {
        isDragging = false;
      };
      svgElement.addEventListener('mouseleave', handleMouseLeave);
      return () => {
        svgElement.removeEventListener('mouseleave', handleMouseLeave);
      };
    }, []);

    return (
      <main>
        { ['top-left', 'top-right', 'bottom-left', 'bottom-right'].map((position, i) => {
          const playerID = i+1
          return(
          <div className={`score ${position}`} id={`score-${playerID}`} key={position}>
             <img className="avatar" src={assets.characters[playerID]} />
             <div className="player-name" id={`player-${playerID}-name`}>{names[i]}</div>
             <div className="player-score" id={`player-${playerID}`}>{scores[i]*100}</div>
           </div>
          )}
        )}
        <svg xmlns="http://www.w3.org/2000/svg" ref={svgRef} viewBox="0 0 800 600" id="game-svg">
          <rect width="100%" height="100%" fill="#000000"/>
        </svg>
      </main>
    );
}

export default BulldogBlast;
