'use client';

import { useEffect, useState } from 'react';

type Punch = {
  id: string;
  device: string;
  punchBy: string;
  count: string;
  time: string;
  force: string;
  receivedAt: string;
  round?: string;
};

type HistoryFile = {
  filename: string;
  name: string;
  time: number;
  size: number;
};

export default function Home() {
  const [punches, setPunches] = useState<Punch[]>([]);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());

  // History State
  const [isViewingHistory, setIsViewingHistory] = useState(false);
  const [historyFiles, setHistoryFiles] = useState<HistoryFile[]>([]);
  const [isHistoryModalOpen, setIsHistoryModalOpen] = useState(false);
  const [loadingHistory, setLoadingHistory] = useState(false);

  // Polling for data every 1 second (only if not viewing history)
  useEffect(() => {
    let interval: NodeJS.Timeout;

    const fetchData = async () => {
      try {
        const res = await fetch('/api/punch');
        const data = await res.json();
        if (Array.isArray(data) && data.length > 0) {
          const latest = data[0];
          const isMatchEnded = latest.punchBy === 'System' && latest.force === 'MatchEnd';
          // Check if data is stale (> 30 mins)
          // Node API should ensure receivedAt is present and ISO
          const now = new Date();
          const received = new Date(latest.receivedAt || now);
          const isStale = (now.getTime() - received.getTime()) > (30 * 60 * 1000);

          if (isViewingHistory) {
            // Auto-Switch to Live if fresh match data detected
            if (!isMatchEnded && !isStale) {
              setIsViewingHistory(false);
              setPunches(data);
              setLastUpdate(new Date());
            }
          } else {
            setPunches(data);
            setLastUpdate(new Date());
          }
        }
      } catch (e) {
        // console.error('Failed to fetch data', e);
      }
    };

    fetchData(); // initial fetch
    interval = setInterval(fetchData, 1000);
    return () => clearInterval(interval);
  }, [isViewingHistory]);

  // Calculate stats
  // Group by round logic would be ideal here if we want exact parity with PHP logic (max per round sum)
  // For now keeping simple distinct count as per original React logic, 
  // but if we want to support "Match Score" correctly with rounds we should implement the grouping logic.
  // Implementing simplified grouping for parity:
  const calculateTotal = (boxer: string) => {
    // 1. Group by round
    const rounds: Record<string, number> = {};
    punches.forEach(p => {
      const r = p.round || '1';
      const val = parseInt(p.count || '0');
      if (p.punchBy === boxer) {
        if (!rounds[r] || val > rounds[r]) {
          rounds[r] = val;
        }
      }
    });
    // 2. Sum max per round
    return Object.values(rounds).reduce((a, b) => a + b, 0);
  };

  const blueTotal = calculateTotal('BlueBoxer');
  const redTotal = calculateTotal('RedBoxer');

  // Winner Logic - Only if LATEST event is MatchEnd
  const hasMatchEnded = punches.length > 0 && punches[0].punchBy === 'System' && punches[0].force === 'MatchEnd';
  let winner = null;
  if (hasMatchEnded) {
    if (blueTotal > redTotal) winner = 'BLUE';
    else if (redTotal > blueTotal) winner = 'RED';
    else winner = 'DRAW';
  }

  // Calculate Live Status for disabling controls
  // Match is LIVE if: Not viewing history, has data, match NOT ended, and data is NOT stale (>30m)
  let isMatchLive = false;
  if (!isViewingHistory && punches.length > 0 && !hasMatchEnded) {
    const last = punches[0];
    const now = new Date();
    // Ensure stable parsing
    const lastTime = new Date(last.receivedAt || new Date());
    const diffMins = (now.getTime() - lastTime.getTime()) / 1000 / 60;
    if (diffMins < 30) {
      isMatchLive = true;
    }
  }

  // Only show overlay if match ended AND NOT viewing history (unless we want to support manual toggle later)
  // For now, per user request: Hide splash screen in history.
  // We use a local state to allow closing it.
  const [showWinnerOverlay, setShowWinnerOverlay] = useState(false);

  useEffect(() => {
    if (hasMatchEnded && !isViewingHistory) {
      // Check freshness (prevent ghost splash on reload)
      let isFresh = false;
      if (punches.length > 0) {
        const last = punches[0];
        // Ensure accurate parsing of receivedAt (ISO string from Node API)
        const lastTime = new Date(last.receivedAt || new Date());
        const now = new Date();
        const diffMins = (now.getTime() - lastTime.getTime()) / 1000 / 60;

        // Show splash only if match ended less than 2 minutes ago
        if (diffMins < 2) {
          isFresh = true;
        }
      }

      if (isFresh) {
        setShowWinnerOverlay(true);
      } else {
        setShowWinnerOverlay(false);
      }
    } else {
      setShowWinnerOverlay(false);
    }
  }, [hasMatchEnded, isViewingHistory, punches]);


  // --- Alert System Effect ---
  // Triggers audio/visual alert if match is live and tab is hidden
  useEffect(() => {
    let alertInterval: NodeJS.Timeout | null = null;
    let originalTitle = document.title || "Box Sensors Live";

    const playBeep = () => {
      try {
        const AudioContext = window.AudioContext || (window as any).webkitAudioContext;
        if (!AudioContext) return;
        const ctx = new AudioContext();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.type = 'square';
        osc.frequency.setValueAtTime(440, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 0.1);
        gain.gain.setValueAtTime(0.1, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5);
        osc.start();
        osc.stop(ctx.currentTime + 0.5);
      } catch (e) { }
    };

    const stopAlert = () => {
      if (alertInterval) {
        clearInterval(alertInterval);
        alertInterval = null;
        document.title = originalTitle;
      }
    };

    const startAlert = () => {
      if (alertInterval) return;
      playBeep();
      if (document.title !== "🔴 LIVE MATCH!") originalTitle = document.title;

      let on = false;
      alertInterval = setInterval(() => {
        document.title = on ? "🔴 LIVE MATCH!" : "Box Sensors Live";
        on = !on;
        if (on) playBeep();
      }, 1000);
    };

    const handleVisibilityChange = () => {
      if (!document.hidden) stopAlert();
      else if (isMatchLive) startAlert();
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    // Initial Check
    if (isMatchLive && document.hidden) {
      startAlert();
    } else {
      stopAlert();
    }

    return () => {
      stopAlert();
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [isMatchLive]);


  const openHistoryModal = async () => {
    setIsHistoryModalOpen(true);
    setLoadingHistory(true);
    try {
      const res = await fetch('/api/history');
      const data = await res.json();
      if (Array.isArray(data)) {
        setHistoryFiles(data);
      }
    } catch (e) {
      console.error("Failed to load history", e);
    } finally {
      setLoadingHistory(false);
    }
  };

  const loadHistoryMatch = async (filename: string) => {
    try {
      setIsHistoryModalOpen(false);
      setIsViewingHistory(true);
      setPunches([]); // clear current

      const res = await fetch(`/api/history/${filename}`);
      const data = await res.json();
      if (Array.isArray(data)) {
        setPunches(data);
        setLastUpdate(new Date()); // update time to now or file time? "Viewing History" status is more important.
      }
    } catch (e) {
      alert('Failed to load match');
      exitHistoryMode();
    }
  };

  const exitHistoryMode = () => {
    setIsViewingHistory(false);
    setPunches([]);
  };

  // Helper to format date DD/MM/YYYY HH:MM:SS
  const formatDateTime = (dateObj: Date) => {
    // Force DD/MM/YYYY
    const dateStr = dateObj.toLocaleDateString('en-GB');
    // Force HH:MM:SS (24h)
    const timeStr = dateObj.toLocaleTimeString('en-GB', { hour12: false });
    return `${dateStr} ${timeStr}`;
  };

  const formatHistoryName = (name: string) => {
    // Input: "2026-01-22 17-13-04"
    const parts = name.split(' ');
    if (parts.length === 2) {
      const dateParts = parts[0].split('-'); // [YYYY, MM, DD]
      const timeParts = parts[1].split('-'); // [HH, mm, ss]
      if (dateParts.length === 3 && timeParts.length === 3) {
        return `${dateParts[2]}/${dateParts[1]}/${dateParts[0]} ${timeParts[0]}:${timeParts[1]}:${timeParts[2]}`;
      }
    }
    return name;
  };

  const resetData = async () => {
    if (!confirm('Are you sure you want to clear all data?')) return;
    try {
      await fetch('/api/punch', { method: 'DELETE' });
      setPunches([]);
      setLastUpdate(new Date());
    } catch (e) {
      alert('Failed to reset');
    }
  };

  return (
    <main className="min-h-screen bg-slate-950 text-white p-4 md:p-8 font-sans">
      {/* Winner Overlay - ONLY show if NOT viewing history (or manually triggered) */}
      {showWinnerOverlay && !isViewingHistory && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm animate-enter">
          <div className={`bg-slate-900 border-4 rounded-2xl p-8 max-w-2xl w-full mx-4 text-center shadow-[0_0_100px_rgba(0,0,0,0.5)] transform scale-110 ${winner === 'BLUE' ? 'border-blue-500 shadow-[0_0_100px_rgba(59,130,246,0.3)]' :
            winner === 'RED' ? 'border-red-500 shadow-[0_0_100px_rgba(239,68,68,0.3)]' :
              'border-slate-500 shadow-[0_0_100px_rgba(255,255,255,0.2)]'
            }`}>
            <div className="text-sm font-bold uppercase tracking-[0.5em] mb-4 text-slate-400">OFFICIAL RESULT</div>
            <div className={`text-5xl md:text-7xl font-black italic uppercase tracking-tighter mb-6 animate-pulse drop-shadow-[0_0_15px_rgba(255,255,255,0.5)] ${winner === 'BLUE' ? 'text-blue-400' :
              winner === 'RED' ? 'text-red-400' :
                'text-white'
              }`}>
              {winner === 'BLUE' ? 'BLUE CORNER' : winner === 'RED' ? 'RED CORNER' : 'DRAW'}
            </div>
            <div className="flex justify-center gap-8 text-2xl font-mono font-bold text-slate-300">
              <div>
                <span className="text-blue-400">BLUE</span> <span>{blueTotal}</span>
              </div>
              <span>-</span>
              <div>
                <span className="text-red-400">RED</span> <span>{redTotal}</span>
              </div>
            </div>
            <button onClick={() => setShowWinnerOverlay(false)} className="mt-8 text-xs text-slate-500 hover:text-white uppercase tracking-widest transition-colors">
              [ Close Result ]
            </button>
          </div>
        </div>
      )}

      <header className="mb-8 flex flex-col md:flex-row justify-between items-center gap-4 max-w-6xl mx-auto border-b border-slate-800 pb-4">
        <div>
          <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
            BOX SENSORS LIVE
          </h1>
          <p className="text-slate-400 text-sm mt-1">Real-time match telemetry</p>
        </div>

        {/* Updated Controls */}
        <div id="historyControls">
          {!isViewingHistory ? (
            <button
              onClick={openHistoryModal}
              disabled={isMatchLive}
              title={isMatchLive ? "Match in progress" : ""}
              className={`text-xs bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-700 px-4 py-2 rounded transition-colors uppercase tracking-wider font-bold flex items-center gap-2 ${isMatchLive ? 'opacity-50 cursor-not-allowed' : ''}`}
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
              Review Matches
            </button>
          ) : (
            <div className="flex flex-col items-center">
              <div className="flex gap-2">
                <button
                  onClick={openHistoryModal}
                  className="text-xs bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-700 px-4 py-2 rounded transition-colors uppercase tracking-wider font-bold flex items-center gap-2"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 6h16M4 10h16M4 14h16M4 18h16"></path>
                  </svg>
                  List
                </button>
                <button
                  onClick={exitHistoryMode}
                  className="text-xs bg-red-900/40 hover:bg-red-900/60 text-red-200 border border-red-800 px-4 py-2 rounded transition-colors uppercase tracking-wider font-bold animate-pulse flex items-center gap-2"
                >
                  <span className="w-2 h-2 bg-red-500 rounded-full animate-ping"></span>
                  Back to Live
                </button>
              </div>
              <div className="text-[10px] text-center text-slate-500 mt-1 uppercase tracking-widest">Viewing History</div>
            </div>
          )}
        </div>

        <div className="text-center md:text-right">
          <div className="text-xs text-slate-500 uppercase tracking-widest mb-1">Status</div>
          <div className="flex items-center gap-4 justify-center md:justify-end">
            <button
              onClick={resetData}
              disabled={isMatchLive}
              title={isMatchLive ? "Match in progress" : ""}
              className={`text-xs bg-red-900/20 hover:bg-red-900/40 text-red-400 border border-red-900/50 px-3 py-1 rounded transition-colors uppercase tracking-wider font-bold ${isMatchLive ? 'opacity-50 cursor-not-allowed' : ''}`}
            >
              Reset Data
            </button>
            {isViewingHistory ? (
              <>
                <span className="relative inline-flex rounded-full h-3 w-3 bg-purple-500"></span>
                <span className="font-mono font-bold text-purple-400">HISTORY</span>
              </>
            ) : (
              <>
                <span className="relative flex h-3 w-3">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                </span>
                <span className="font-mono text-green-400">ONLINE</span>
              </>
            )}
          </div>
        </div>
      </header>

      {/* History Modal */}
      {isHistoryModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm animate-enter">
          <div className="bg-slate-900 border border-slate-700 rounded-2xl p-6 max-w-lg w-full mx-4 shadow-2xl">
            <div className="flex justify-between items-center mb-6 border-b border-slate-800 pb-4">
              <h3 className="text-lg font-bold text-slate-200">Match History</h3>
              <button onClick={() => setIsHistoryModalOpen(false)} className="text-slate-500 hover:text-white transition-colors">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>
            <div className="max-h-[60vh] overflow-y-auto space-y-2 pr-2">
              {loadingHistory ? (
                <div className="text-center text-slate-500 py-8 italic">Loading...</div>
              ) : historyFiles.length === 0 ? (
                <div className="text-center text-slate-500 py-8 italic">No archived matches found.</div>
              ) : (
                historyFiles.map((file) => {
                  let displayTime = file.name;
                  // match_2026-01-22_19-30-44.json
                  const match = file.filename.match(/match_(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})/);

                  if (match) {
                    const [_, y, m, d, h, min, s] = match;
                    // Construct UTC ISO string for accurate local conversion
                    const isoStr = `${y}-${m}-${d}T${h}:${min}:${s}Z`;
                    const dateObj = new Date(isoStr);
                    displayTime = `${dateObj.toLocaleDateString('en-GB')} ${dateObj.toLocaleTimeString('en-GB', { hour12: false })}`;
                  } else {
                    // Fallback
                    const dateObj = new Date(file.time * 1000);
                    displayTime = `${dateObj.toLocaleDateString('en-GB')} ${dateObj.toLocaleTimeString('en-GB', { hour12: false })}`;
                  }

                  return (
                    <div
                      key={file.filename}
                      onClick={() => loadHistoryMatch(file.filename)}
                      className="bg-slate-950/50 hover:bg-slate-800 border border-slate-800 p-4 rounded-lg cursor-pointer transition-colors group"
                    >
                      <div className="flex justify-between items-center">
                        <span className="font-mono text-slate-300 font-bold group-hover:text-blue-400 transition-colors">
                          {displayTime}
                        </span>
                      </div>
                      <div className="text-xs text-slate-600 mt-1">{(file.size / 1024).toFixed(1)} KB</div>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        </div>
      )}

      <div className="max-w-6xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        {/* Blue Team Card */}
        <div className="bg-slate-900/50 border border-blue-900/50 rounded-2xl p-6 backdrop-blur-sm relative overflow-hidden group">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <div className="w-32 h-32 bg-blue-500 rounded-full blur-3xl"></div>
          </div>
          <h2 className="text-blue-400 font-bold tracking-wider mb-2">BLUE CORNER</h2>
          <div className="flex items-baseline gap-2">
            <span className="text-6xl font-black text-white">{blueTotal}</span>
            <span className="text-blue-200/50 font-medium">punches</span>
          </div>
        </div>

        {/* Red Team Card */}
        <div className="bg-slate-900/50 border border-red-900/50 rounded-2xl p-6 backdrop-blur-sm relative overflow-hidden group">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <div className="w-32 h-32 bg-red-500 rounded-full blur-3xl"></div>
          </div>
          <h2 className="text-red-400 font-bold tracking-wider mb-2">RED CORNER</h2>
          <div className="flex items-baseline gap-2">
            <span className="text-6xl font-black text-white">{redTotal}</span>
            <span className="text-red-200/50 font-medium">punches</span>
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto">
        <h3 className="text-xl font-bold mb-4 flex items-center gap-2">
          <span className="w-1 h-6 bg-purple-500 rounded-full"></span>
          Live Feed
          <span className="text-xs font-normal text-slate-500 ml-auto">
            Last update: {lastUpdate.toLocaleTimeString()}
          </span>
        </h3>

        <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden shadow-2xl">
          <div className="overflow-x-auto h-[600px]">
            <table className="w-full text-left border-collapse">
              <thead className="sticky top-0 z-10 bg-slate-900 shadow-sm">
                <tr className="border-b border-slate-800 text-slate-400 text-xs uppercase tracking-wider">
                  <th className="p-4 font-semibold">Time</th>
                  <th className="p-4 font-semibold">Round</th>
                  <th className="p-4 font-semibold text-center">Punch By</th>
                  <th className="p-4 font-semibold text-right">Force (mV)</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {punches.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="p-12 text-center text-slate-500 italic">
                      Waiting for match data...
                    </td>
                  </tr>
                ) : (
                  punches.map((punch, idx) => (
                    <tr key={idx} className="hover:bg-slate-800/50 transition-colors">
                      <td className="p-4 font-mono text-slate-300">
                        {punch.time}
                      </td>
                      <td className="p-4 font-mono text-slate-400">
                        R{punch.round || '1'}
                      </td>
                      <td className="p-4 text-center">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${punch.punchBy === 'BlueBoxer'
                          ? 'bg-blue-900/30 text-blue-400 border-blue-800'
                          : 'bg-red-900/30 text-red-400 border-red-800'
                          }`}>
                          {punch.punchBy}
                        </span>
                      </td>
                      <td className="p-4 text-right font-mono text-emerald-400 font-bold">
                        {punch.force}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </main>
  );
}

