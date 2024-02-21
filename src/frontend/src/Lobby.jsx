import React, { useEffect, useState } from 'react';
import logo from "../assets/logo2.svg";
import LogoBulldogBlast from "../assets/Logo-Bulldog-Blast.svg";
import LogoOptiGamesKO from "../assets/Logo-OptiGames-KO.svg";
import { lobby } from "../../declarations/lobby"
import canisters from "../../../.dfx/local/canister_ids.json";
import green from "../assets/characters/green.png";
import orange from "../assets/characters/orange.png";
import red from "../assets/characters/red.png";
import violet from "../assets/characters/violet.png";
const characters = { 1: green, 2: orange, 3: red, 4: violet }

const Lobby = ( { handleGameStart } ) => {

    const [queue, setQueue] = useState([]);
    const [playerName, setPlayerName] = useState('');
    const [playerID, setPlayerID ] = useState(null);
    const [gameID, setGameID ] = useState(null);
    const [isJoiningQueue, setIsJoiningQueue] = useState(false);

    const pollLobby = async () => {
      const newQueue = await lobby.getQueue()
      setQueue(newQueue);
      if (gameID != null) {
        const gameStatus = await lobby.gameStatus(gameID)
        if ("Active" in gameStatus) {
          handleGameStart(gameID, playerID)
        }
      }
    }

    useEffect(() => {
      pollLobby();
      const intervalId = setInterval(pollLobby, 1000);
      return () => clearInterval(intervalId);
    }, [ gameID ]); 

    const handleJoinQueue = async () => {
      if (playerName.trim() == '') { return };
      setIsJoiningQueue(true)
      let queueJoinResult = await lobby.joinQueue(playerName);
      setPlayerID(queueJoinResult.playerID)
      setGameID(queueJoinResult.gameID)
    };

    return (
      <main>
        <div id="title-row">
          <img width="35%" src={ LogoOptiGamesKO } alt="OptiGames logo" />      
          <p> presents </p>
          <img src={ LogoBulldogBlast } width="50%" alt="Bulldog Blast title" />
        </div>
        <p>the explosive vehicular combat experience.</p>
        <img src={ logo } width="50%" alt="dfinity logo" />
	<div>
	    <p>In the game, click to launch a bomb. Click and drag to set a thrust. Turns tick forward every 5 seconds.</p>
	</div>
        <br />
        {(gameID == null) ? 
        <div id="title-row">
          <label for="name">Enter name: &nbsp;</label>
          <input id="playerName" alt="Name" type="text"
            value={playerName} 
            onChange={(e) => setPlayerName(e.target.value)}  />
          <button 
            onClick = {handleJoinQueue}
            id="joinqueue" disabled={isJoiningQueue}>Join Queue</button>
        </div> :
        <div>
          Waiting for game...
        </div>
      }
        <div>
          Game Queue:
          <div id="queue-row">
            {queue.map((queue, i) => (
                <div class="queue-slot" id={`queue-${i+1}`}>
                  <div class="character-image" id={`character-${i+1}`}>
                    <img src={characters[i+1]}/>
                  </div>
                  <div class="player-name" id={`player-${i+1}`}>{queue.name}</div>
                </div>
            ))}
          </div>
        </div>
        <br/>
      </main>
    );
}

export default Lobby;
