/**
 * Tournament System Integration Tests
 * Tests the complete tournament workflow
 */

const request = require('supertest');
const { Pool } = require('pg');
const app = require('../../test-app-fixed');

describe('Tournament Integration Tests', () => {
  let testApp;
  let mockDb;
  let server;

  beforeAll(async () => {
    // Create mock database
    mockDb = {
      query: jest.fn(),
      connect: jest.fn().mockResolvedValue({}),
      release: jest.fn(),
      end: jest.fn()
    };

    // Create test app with mocked dependencies
    testApp = app.createTestApp({
      db: mockDb,
      redis: null,
      antiCheatEngine: { validateScore: jest.fn().mockResolvedValue({ isValid: true }) },
      cacheManager: { get: jest.fn(), set: jest.fn(), delete: jest.fn() },
      leaderboardService: null
    });

    server = testApp.listen(0); // Use random port
  });

  afterAll(async () => {
    if (server) {
      server.close();
    }
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Tournament Lifecycle', () => {
    test('should get current tournament (none active)', async () => {
      // Mock no active tournament
      mockDb.query.mockResolvedValueOnce({
        rows: []
      });

      const response = await request(testApp)
        .get('/api/tournaments/current')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.tournament).toBeNull();
      expect(response.body.message).toBe('No active tournament');
    });

    test('should get current active tournament', async () => {
      const mockTournament = {
        id: '123e4567-e89b-12d3-a456-426614174000',
        name: 'Weekly Championship 2024-01-15',
        tournament_type: 'weekly',
        start_date: '2024-01-15T00:00:00Z',
        end_date: '2024-01-21T23:59:59Z',
        status: 'active',
        prize_pool: 1000,
        participant_count: 50,
        time_remaining: '2 days 5 hours'
      };

      mockDb.query.mockResolvedValueOnce({
        rows: [mockTournament]
      });

      const response = await request(testApp)
        .get('/api/tournaments/current')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.tournament).toEqual(mockTournament);
    });

    test('should get tournament leaderboard', async () => {
      const tournamentId = '123e4567-e89b-12d3-a456-426614174000';
      const mockLeaderboard = [
        { player_id: 'player1', player_name: 'Leader', score: 2000, rank: 1 },
        { player_id: 'player2', player_name: 'Second', score: 1800, rank: 2 },
        { player_id: 'player3', player_name: 'Third', score: 1600, rank: 3 }
      ];

      mockDb.query.mockResolvedValueOnce({
        rows: mockLeaderboard
      });

      const response = await request(testApp)
        .get(`/api/tournaments/${tournamentId}/leaderboard`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.leaderboard).toEqual(mockLeaderboard);
      expect(response.body.pagination).toEqual({
        limit: 50,
        offset: 0,
        hasMore: false
      });
    });

    test('should handle invalid tournament ID', async () => {
      const response = await request(testApp)
        .get('/api/tournaments/invalid-id/leaderboard')
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Validation failed');
    });
  });

  describe('Tournament Registration', () => {
    test('should require authentication for registration', async () => {
      const tournamentId = '123e4567-e89b-12d3-a456-426614174000';

      const response = await request(testApp)
        .post(`/api/tournaments/${tournamentId}/register`)
        .send({ playerName: 'TestPlayer' })
        .expect(401);

      expect(response.body.error).toContain('token');
    });
  });

  describe('Score Submission', () => {
    test('should require authentication for score submission', async () => {
      const tournamentId = '123e4567-e89b-12d3-a456-426614174000';

      const response = await request(testApp)
        .post(`/api/tournaments/${tournamentId}/scores`)
        .send({ score: 1500 })
        .expect(401);

      expect(response.body.error).toContain('token');
    });
  });

  describe('Admin Operations', () => {
    test('should require admin access for tournament creation', async () => {
      const response = await request(testApp)
        .post('/api/tournaments/create-weekly')
        .send({ prizePool: 1000 })
        .expect(401);

      expect(response.body.error).toContain('token');
    });
  });

  describe('Error Handling', () => {
    test('should handle database errors gracefully', async () => {
      mockDb.query.mockRejectedValueOnce(new Error('Database connection failed'));

      const response = await request(testApp)
        .get('/api/tournaments/current')
        .expect(500);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Internal server error');
    });

    test('should validate tournament ID format', async () => {
      const response = await request(testApp)
        .get('/api/tournaments/not-a-uuid/leaderboard')
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Validation failed');
    });

    test('should validate score submission data', async () => {
      const tournamentId = '123e4567-e89b-12d3-a456-426614174000';

      const response = await request(testApp)
        .post(`/api/tournaments/${tournamentId}/scores`)
        .set('Authorization', 'Bearer valid-token')
        .send({ score: -100 }) // Invalid negative score
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Validation failed');
    });
  });
});
