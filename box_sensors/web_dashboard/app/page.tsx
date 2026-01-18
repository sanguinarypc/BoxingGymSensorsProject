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
};

export default function Home() {
  const [punches, setPunches] = useState<Punch[]>([]);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());

  // Polling for data every 1 second
  useEffect(() => {
    const fetchData = async () => {
      try {
        const res = await fetch('/api/punch');
        const data = await res.json();
        if (Array.isArray(data)) {
          setPunches(data);
          setLastUpdate(new Date());
        }
      } catch (e) {
        console.error('Failed to fetch data', e);
      }
    };

    fetchData(); // initial fetch
    const interval = setInterval(fetchData, 1000);
    return () => clearInterval(interval);
  }, []);

  // Calculate stats
  const bluePunches = punches.filter(p => p.punchBy === 'BlueBoxer').length;
  const redPunches = punches.filter(p => p.punchBy === 'RedBoxer').length;

  return (
    <main className="min-h-screen bg-slate-950 text-white p-4 md:p-8 font-sans">
      <header className="mb-8 flex justify-between items-center max-w-6xl mx-auto border-b border-slate-800 pb-4">
        <div>
          <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
            BOX SENSORS LIVE
          </h1>
          <p className="text-slate-400 text-sm mt-1">Real-time match telemetry</p>
        </div>
        <div className="text-right">
          <div className="text-xs text-slate-500 uppercase tracking-widest">Status</div>
          <div className="flex items-center gap-2 justify-end">
            <span className="relative flex h-3 w-3">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
            </span>
            <span className="font-mono text-green-400">ONLINE</span>
          </div>
        </div>
      </header>

      <div className="max-w-6xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        {/* Blue Team Card */}
        <div className="bg-slate-900/50 border border-blue-900/50 rounded-2xl p-6 backdrop-blur-sm relative overflow-hidden group">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <div className="w-32 h-32 bg-blue-500 rounded-full blur-3xl"></div>
          </div>
          <h2 className="text-blue-400 font-bold tracking-wider mb-2">BLUE CORNER</h2>
          <div className="flex items-baseline gap-2">
            <span className="text-6xl font-black text-white">{bluePunches}</span>
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
            <span className="text-6xl font-black text-white">{redPunches}</span>
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
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-800 bg-slate-950/50 text-slate-400 text-xs uppercase tracking-wider">
                  <th className="p-4 font-semibold">Time</th>
                  <th className="p-4 font-semibold">Source</th>
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
                  punches.map((punch) => (
                    <tr key={punch.id} className="hover:bg-slate-800/50 transition-colors">
                      <td className="p-4 font-mono text-slate-300">
                        {punch.time}
                      </td>
                      <td className="p-4 text-slate-400">
                        {punch.device}
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
