import { config } from './config';
import { ctx } from './index';
import { Observable } from 'rxjs';
import { GameState } from './gameState';
import { triggerEvery } from './util';
import { map } from 'rxjs/operators';

let playerAvatar = './img/ship.png';
let playerImg = document.createElement('img');
playerImg.src = playerAvatar;

// START: config
let playerFire = (gameState: GameState) => {
  let availableLaser = gameState.player.lasers.find(l => l.y
                       - config.laser.height < 0);
  if (!availableLaser) { return gameState; }
  availableLaser.x = gameState.player.x + (config.ship.width / 2)
                     - (config.laser.width / 2);
  availableLaser.y = gameState.player.y;
  return gameState;
};
let fiveHundredMs = () => 500;
let isSpacebar = (gameState: GameState) =>
                 gameState.keyStatus[config.controls.fireLaser];
// END: config

// START: updatePlayerLasers
function updatePlayerLasers(gameState: GameState): GameState {
  // Lasers actually move
  gameState.player.lasers
    .forEach(l => {
      l.y -= config.laser.speed;
    });
  return gameState;
}
// END: updatePlayerLasers

// START: updatePlayerStatus1
function updatePlayerState(gameState: GameState): GameState {
  if (gameState.keyStatus[config.controls.left]) {
    gameState.player.x -= config.ship.speed;
  }
  if (gameState.keyStatus[config.controls.right]) {
    gameState.player.x += config.ship.speed;
  }
  // END: updatePlayerStatus1
  // START: updatePlayerStatus2
  if (gameState.player.x < 0) {
    gameState.player.x = 0;
  }
  if (gameState.player.x > (config.canvas.width - config.ship.width)) {
    gameState.player.x = (config.canvas.width - config.ship.width);
  }
  return gameState;
}
// END: updatePlayerStatus2

// START: updatePlayer
export const updatePlayer = (obs: Observable<GameState>) => {
  return obs
  .pipe(
    map(updatePlayerState),
    map(updatePlayerLasers),
    triggerEvery(playerFire, fiveHundredMs, isSpacebar)
  );
};
// END: updatePlayer

// START: renderPlayer
export function renderPlayer(state: GameState) {
  if (!state.player.alive) { return; }
  ctx.drawImage(playerImg, state.player.x, state.player.y);
}
// END: renderPlayer
