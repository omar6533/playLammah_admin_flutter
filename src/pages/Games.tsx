import { useEffect, useState } from 'react';
import { Eye } from 'lucide-react';
import { gamesApi, type Game, type GamePlayer } from '../lib/api';
import Modal from '../components/Modal';
import Badge from '../components/Badge';

export default function Games() {
  const [games, setGames] = useState<Game[]>([]);
  const [loading, setLoading] = useState(true);
  const [viewModalOpen, setViewModalOpen] = useState(false);
  const [selectedGame, setSelectedGame] = useState<Game | null>(null);
  const [gamePlayers, setGamePlayers] = useState<GamePlayer[]>([]);
  const [loadingPlayers, setLoadingPlayers] = useState(false);

  useEffect(() => {
    loadGames();
  }, []);

  const loadGames = async () => {
    try {
      const data = await gamesApi.getAll();
      setGames(data);
    } catch (error) {
      console.error('Error loading games:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleViewDetails = async (game: Game) => {
    setSelectedGame(game);
    setViewModalOpen(true);
    setLoadingPlayers(true);
    try {
      const players = await gamesApi.getPlayers(game.id);
      setGamePlayers(players);
    } catch (error) {
      console.error('Error loading game players:', error);
    } finally {
      setLoadingPlayers(false);
    }
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getStatusVariant = (status: string): 'success' | 'warning' | 'info' => {
    switch (status) {
      case 'finished':
        return 'success';
      case 'playing':
        return 'warning';
      case 'waiting':
        return 'info';
      default:
        return 'info';
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading games...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Games</h1>
        <p className="text-gray-600 mt-1">View all game sessions (Read-only)</p>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Room Code
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Created At
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Players
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Status
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Finished At
                </th>
                <th className="text-right px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {games.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                    No games found.
                  </td>
                </tr>
              ) : (
                games.map((game) => (
                  <tr key={game.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <p className="text-sm font-mono font-bold text-blue-600">{game.room_code}</p>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {formatDate(game.created_at)}
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-gray-900 font-semibold">
                        {game.players_count} {game.players_count === 1 ? 'Player' : 'Players'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <Badge variant={getStatusVariant(game.status)}>
                        {game.status.charAt(0).toUpperCase() + game.status.slice(1)}
                      </Badge>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {formatDate(game.finished_at)}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-end">
                        <button
                          onClick={() => handleViewDetails(game)}
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="View Details"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal
        isOpen={viewModalOpen}
        onClose={() => setViewModalOpen(false)}
        title="Game Details"
        size="md"
      >
        {selectedGame && (
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <h3 className="text-sm font-semibold text-gray-700 mb-2">Room Code</h3>
                <p className="text-lg font-mono font-bold text-blue-600">{selectedGame.room_code}</p>
              </div>
              <div>
                <h3 className="text-sm font-semibold text-gray-700 mb-2">Status</h3>
                <Badge variant={getStatusVariant(selectedGame.status)}>
                  {selectedGame.status.charAt(0).toUpperCase() + selectedGame.status.slice(1)}
                </Badge>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <h3 className="text-sm font-semibold text-gray-700 mb-2">Created At</h3>
                <p className="text-gray-900">{formatDate(selectedGame.created_at)}</p>
              </div>
              <div>
                <h3 className="text-sm font-semibold text-gray-700 mb-2">Finished At</h3>
                <p className="text-gray-900">{formatDate(selectedGame.finished_at)}</p>
              </div>
            </div>

            <div>
              <h3 className="text-sm font-semibold text-gray-700 mb-3">
                Players ({selectedGame.players_count})
              </h3>
              {loadingPlayers ? (
                <div className="text-center py-4 text-gray-500">Loading players...</div>
              ) : gamePlayers.length === 0 ? (
                <div className="text-center py-4 text-gray-500">No players yet</div>
              ) : (
                <div className="space-y-2">
                  {gamePlayers.map((player, index) => (
                    <div
                      key={player.id}
                      className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-200"
                    >
                      <div className="flex items-center gap-3">
                        <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-white ${
                          index === 0 ? 'bg-yellow-500' :
                          index === 1 ? 'bg-gray-400' :
                          index === 2 ? 'bg-orange-600' :
                          'bg-blue-500'
                        }`}>
                          {index + 1}
                        </div>
                        <span className="font-medium text-gray-900">{player.player_name}</span>
                      </div>
                      <span className="text-lg font-bold text-blue-600">{player.score} pts</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
