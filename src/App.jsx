import React, { useState, useEffect, useMemo } from 'react';

const FIREBASE_URL = 'https://straatambassadeurs-planner-default-rtdb.europe-west1.firebasedatabase.app';
const APP_URL = 'https://kerngroep.netlify.app';

const DEFAULT_PARTICIPANTS = [
  { id: 'p1', name: 'Carien', email: '' },
  { id: 'p2', name: 'Kundike', email: '' },
  { id: 'p3', name: 'Bejanca', email: '' },
  { id: 'p4', name: 'Gerry', email: '' },
  { id: 'p5', name: 'Stefan', email: '' },
  { id: 'p6', name: 'Richard', email: '' }
];

const createInitialEvent = () => ({
  id: 'evt_' + Date.now(),
  title: 'Vergadering 1 - 2026',
  time: '19:45 - 21:15',
  dates: [
    { id: 'd1', date: '2025-02-03', label: 'Di 3 feb' },
    { id: 'd2', date: '2025-02-05', label: 'Do 5 feb' },
    { id: 'd3', date: '2025-02-06', label: 'Vr 6 feb' },
    { id: 'd4', date: '2025-02-10', label: 'Di 10 feb' },
    { id: 'd5', date: '2025-02-12', label: 'Do 12 feb' }
  ],
  participants: DEFAULT_PARTICIPANTS,
  responses: {},
  locations: [],
  comments: [],
  created: new Date().toISOString()
});

export default function VergaderPlanner() {
  const [data, setData] = useState(null);
  const [selectedMember, setSelectedMember] = useState(() => localStorage.getItem('sa-member') || '');
  const [activeEventId, setActiveEventId] = useState(null);
  const [view, setView] = useState('poll');
  const [online, setOnline] = useState(false);
  const [modal, setModal] = useState(null);
  const [copied, setCopied] = useState(false);
  
  // Form states
  const [newDate, setNewDate] = useState('');
  const [newEventTitle, setNewEventTitle] = useState('');
  const [newEventTime, setNewEventTime] = useState('19:45 - 21:15');
  const [newParticipant, setNewParticipant] = useState({ name: '', email: '' });
  const [newLocation, setNewLocation] = useState({ name: '', address: '', proposedBy: '' });
  const [newComment, setNewComment] = useState('');

  // Load from Firebase
  useEffect(() => {
    const loadData = async () => {
      if (FIREBASE_URL.includes('YOUR-PROJECT')) {
        const initial = { events: [createInitialEvent()] };
        setData(initial);
        setActiveEventId(initial.events[0].id);
        return;
      }
      try {
        const res = await fetch(`${FIREBASE_URL}/planner.json`);
        const d = await res.json();
        if (d && d.events?.length) {
          setData(d);
          setActiveEventId(d.events[0].id);
        } else {
          const initial = { events: [createInitialEvent()] };
          await fetch(`${FIREBASE_URL}/planner.json`, { method: 'PUT', body: JSON.stringify(initial) });
          setData(initial);
          setActiveEventId(initial.events[0].id);
        }
        setOnline(true);
      } catch (e) {
        const initial = { events: [createInitialEvent()] };
        setData(initial);
        setActiveEventId(initial.events[0].id);
      }
    };
    loadData();
  }, []);

  // Realtime sync
  useEffect(() => {
    if (FIREBASE_URL.includes('YOUR-PROJECT') || !data) return;
    const interval = setInterval(async () => {
      try {
        const res = await fetch(`${FIREBASE_URL}/planner.json`);
        const d = await res.json();
        if (d) setData(d);
        setOnline(true);
      } catch { setOnline(false); }
    }, 3000);
    return () => clearInterval(interval);
  }, [data]);

  useEffect(() => {
    if (selectedMember) localStorage.setItem('sa-member', selectedMember);
  }, [selectedMember]);

  const saveData = async (newData) => {
    setData(newData);
    if (!FIREBASE_URL.includes('YOUR-PROJECT')) {
      try {
        await fetch(`${FIREBASE_URL}/planner.json`, { method: 'PUT', body: JSON.stringify(newData) });
      } catch (e) { console.log('Save failed'); }
    }
  };

  const event = useMemo(() => data?.events?.find(e => e.id === activeEventId), [data, activeEventId]);
  
  const participants = event?.participants || [];
  const orderedParticipants = useMemo(() => {
    if (!selectedMember) return participants;
    const me = participants.find(p => p.name === selectedMember);
    if (!me) return participants;
    return [me, ...participants.filter(p => p.name !== selectedMember)];
  }, [participants, selectedMember]);

  const calcPct = (dateId) => {
    if (!event) return 0;
    let score = 0;
    const total = participants.length;
    participants.forEach(p => {
      const v = event.responses?.[p.id]?.[dateId];
      if (v === 'ja') score += (100 / total);
      else if (v === 'misschien') score += (50 / total);
    });
    return Math.round(score * 10) / 10;
  };

  const handleVote = (participantId, dateId, vote) => {
    const newEvents = data.events.map(e => {
      if (e.id !== activeEventId) return e;
      return { ...e, responses: { ...e.responses, [participantId]: { ...e.responses?.[participantId], [dateId]: vote } } };
    });
    saveData({ ...data, events: newEvents });
  };

  const formatDateLabel = (dateStr) => {
    const d = new Date(dateStr);
    const days = ['Zo', 'Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za'];
    const months = ['jan', 'feb', 'mrt', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'];
    return `${days[d.getDay()]} ${d.getDate()} ${months[d.getMonth()]}`;
  };

  const addDate = () => {
    if (!newDate) return;
    const newEvents = data.events.map(e => {
      if (e.id !== activeEventId) return e;
      return { ...e, dates: [...e.dates, { id: 'd' + Date.now(), date: newDate, label: formatDateLabel(newDate) }] };
    });
    saveData({ ...data, events: newEvents });
    setNewDate('');
  };

  const deleteDate = (dateId) => {
    const newEvents = data.events.map(e => {
      if (e.id !== activeEventId) return e;
      const newResponses = { ...e.responses };
      Object.keys(newResponses).forEach(pid => { delete newResponses[pid][dateId]; });
      return { ...e, dates: e.dates.filter(d => d.id !== dateId), responses: newResponses };
    });
    saveData({ ...data, events: newEvents });
    setModal(null);
  };

  const createEvent = () => {
    if (!newEventTitle) return;
    const newEvent = {
      id: 'evt_' + Date.now(),
      title: newEventTitle,
      time: newEventTime,
      dates: [],
      participants: DEFAULT_PARTICIPANTS,
      responses: {},
      locations: [],
      comments: [],
      created: new Date().toISOString()
    };
    saveData({ ...data, events: [...data.events, newEvent] });
    setActiveEventId(newEvent.id);
    setNewEventTitle('');
    setNewEventTime('19:45 - 21:15');
    setView('poll');
  };

  const deleteEvent = (eventId) => {
    if (data.events.length <= 1) return;
    const newEvents = data.events.filter(e => e.id !== eventId);
    saveData({ ...data, events: newEvents });
    setActiveEventId(newEvents[0].id);
    setModal(null);
  };

  const addParticipant = () => {
    if (!newParticipant.name) return;
    const newEvents = data.events.map(e => {
      if (e.id !== activeEventId) return e;
      return { ...e, participants: [...e.participants, { id: 'p' + Date.now(), ...newParticipant }] };
    });
    saveData({ ...data, events: newEvents });
    setNewParticipant({ name: '', email: '' });
  };

  const removeParticipant = (pid) => {
    const newEvents = data.events.map(e => {
      if (e.id !== activeEventId) return e;
      const newResponses = { ...e.responses };
      delete newResponses[pid];
      return { ...e, participants: e.participants.filter(p => p.id !== pid), responses: newResponses };
    });
    saveData({ ...data, events: newEvents });
    setModal(null);
  };

  const addLocation = () => {
    if (!newLocation.name) return;
    const newEvents = data.events.map(e => {
      if (e.id !== activeEventId) return e;
      return { ...e, locations: [...(e.locations || []), { id: 'loc' + Date.now(), ...newLocation, votes: [] }] };
    });
    saveData({ ...data, events: newEvents });
    setNewLocation({ name: '', address: '', proposedBy: selectedMember || '' });
  };

  const voteLocation = (locId) => {
    if (!selectedMember) return;
    const p = participants.find(p => p.name === selectedMember);
    if (!p) return;
    const newEvents = data.events.map(e => {
      if (e.id !== activeEventId) return e;
      const newLocs = e.locations.map(loc => {
        if (loc.id !== locId) return loc;
        const votes = loc.votes || [];
        if (votes.includes(p.id)) return { ...loc, votes: votes.filter(v => v !== p.id) };
        return { ...loc, votes: [...votes, p.id] };
      });
      return { ...e, locations: newLocs };
    });
    saveData({ ...data, events: newEvents });
  };

  const deleteLocation = (locId) => {
    const newEvents = data.events.map(e => {
      if (e.id !== activeEventId) return e;
      return { ...e, locations: e.locations.filter(l => l.id !== locId) };
    });
    saveData({ ...data, events: newEvents });
    setModal(null);
  };

  const addComment = () => {
    if (!newComment || !selectedMember) return;
    const newEvents = data.events.map(e => {
      if (e.id !== activeEventId) return e;
      return { ...e, comments: [...(e.comments || []), { id: 'c' + Date.now(), author: selectedMember, text: newComment, time: new Date().toLocaleString('nl-NL', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) }] };
    });
    saveData({ ...data, events: newEvents });
    setNewComment('');
  };

  const generateSummary = () => {
    if (!event) return '';
    const responded = new Set();
    Object.keys(event.responses || {}).forEach(pid => {
      if (Object.keys(event.responses[pid]).length > 0) responded.add(pid);
    });
    const notResponded = participants.filter(p => !responded.has(p.id));
    
    const sortedDates = [...event.dates].sort((a, b) => calcPct(b.id) - calcPct(a.id));
    const bestDate = sortedDates[0];
    const bestPct = bestDate ? calcPct(bestDate.id) : 0;

    let msg = `📊 *${event.title}* - Tussenstand\n\n`;
    msg += `⏰ Tijd: ${event.time}\n\n`;
    
    if (bestDate) {
      msg += `🏆 Beste optie: *${bestDate.label}* (${bestPct}%)\n\n`;
      msg += `📅 Alle opties:\n`;
      sortedDates.forEach(d => {
        msg += `• ${d.label}: ${calcPct(d.id)}%\n`;
      });
    }

    if (event.locations?.length) {
      msg += `\n📍 Voorgestelde locaties:\n`;
      event.locations.forEach(loc => {
        msg += `• ${loc.name}${loc.address ? ` (${loc.address})` : ''} - ${loc.votes?.length || 0} stemmen\n`;
      });
    }

    msg += `\n✅ Gereageerd: ${responded.size}/${participants.length}\n`;
    
    if (notResponded.length > 0) {
      msg += `\n⏳ Nog niet gereageerd:\n`;
      notResponded.forEach(p => { msg += `• ${p.name}\n`; });
      msg += `\n👉 Vul je beschikbaarheid in: ${APP_URL}`;
    } else {
      msg += `\n🎉 Iedereen heeft gereageerd!`;
    }

    return msg;
  };

  const copySummary = () => {
    navigator.clipboard.writeText(generateSummary());
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const sendInviteEmail = (participant) => {
    if (!participant.email) return;
    const subject = encodeURIComponent(`Uitnodiging: ${event?.title || 'Vergadering'}`);
    const body = encodeURIComponent(`Hoi ${participant.name},\n\nJe wordt uitgenodigd om je beschikbaarheid door te geven voor "${event?.title}".\n\n🔗 Ga naar: ${APP_URL}\n\nSelecteer je naam en geef je voorkeuren aan.\n\nGroet,\nStraatambassadeurs Kerngroep`);
    window.open(`mailto:${participant.email}?subject=${subject}&body=${body}`);
  };

  const getIcon = (v) => v === 'ja' ? '✓' : v === 'misschien' ? '?' : v === 'nee' ? '✗' : '·';
  const getColor = (v) => v === 'ja' ? '#2e7d32' : v === 'misschien' ? '#f9a825' : v === 'nee' ? '#c62828' : '#ccc';

  if (!data || !event) return <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#e8f0f8' }}>Laden...</div>;

  return (
    <div style={{ minHeight: '100vh', background: 'linear-gradient(135deg, #e8f0f8, #f5f8fc)', fontFamily: 'system-ui, sans-serif', paddingBottom: '20px' }}>
      {/* Header */}
      <div style={{ background: 'linear-gradient(135deg, #1e5799, #2a6db5)', padding: '10px 12px', position: 'sticky', top: 0, zIndex: 100 }}>
        <div style={{ maxWidth: '600px', margin: '0 auto' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{ background: 'white', borderRadius: '6px', padding: '4px 8px', transform: 'rotate(-2deg)', flexShrink: 0 }}>
              <div style={{ fontSize: '13px', fontWeight: '800', color: '#1e5799', lineHeight: 1 }}>STRAAT</div>
              <div style={{ background: '#1e5799', color: 'white', fontSize: '6px', fontWeight: '600', padding: '1px 4px', borderRadius: '2px', textAlign: 'center' }}>AMBASSADEURS</div>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <select value={activeEventId} onChange={(e) => setActiveEventId(e.target.value)} style={{ width: '100%', padding: '4px 8px', fontSize: '13px', fontWeight: '600', borderRadius: '4px', border: 'none', background: 'rgba(255,255,255,0.9)', color: '#1e5799' }}>
                {data.events.map(e => <option key={e.id} value={e.id}>{e.title}</option>)}
              </select>
              <div style={{ color: 'rgba(255,255,255,0.85)', fontSize: '10px', marginTop: '2px' }}>🕐 {event.time} • {online ? '🟢 Live' : '⚪ Offline'}</div>
            </div>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <div style={{ maxWidth: '600px', margin: '0 auto', padding: '8px' }}>
        <div style={{ display: 'flex', gap: '4px', background: 'white', borderRadius: '8px', padding: '4px', boxShadow: '0 1px 4px rgba(0,0,0,0.1)' }}>
          {[{ id: 'poll', icon: '📊', label: 'Poll' }, { id: 'events', icon: '📅', label: 'Events' }, { id: 'participants', icon: '👥', label: 'Leden' }, { id: 'locations', icon: '📍', label: 'Locaties' }, { id: 'summary', icon: '📋', label: 'Delen' }].map(tab => (
            <button key={tab.id} onClick={() => setView(tab.id)} style={{ flex: 1, padding: '8px 4px', background: view === tab.id ? '#1e5799' : 'transparent', color: view === tab.id ? 'white' : '#1e5799', border: 'none', borderRadius: '6px', fontSize: '11px', fontWeight: '600', cursor: 'pointer', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '2px' }}>
              <span style={{ fontSize: '14px' }}>{tab.icon}</span>
              <span>{tab.label}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div style={{ maxWidth: '600px', margin: '0 auto', padding: '0 8px' }}>
        
        {/* POLL VIEW */}
        {view === 'poll' && (
          <div style={{ background: 'white', borderRadius: '10px', padding: '12px', boxShadow: '0 2px 8px rgba(30,87,153,0.1)' }}>
            <select value={selectedMember} onChange={(e) => setSelectedMember(e.target.value)} style={{ width: '100%', padding: '8px 10px', fontSize: '13px', borderRadius: '6px', border: '2px solid #1e5799', marginBottom: '10px', fontWeight: '500', color: '#1e5799' }}>
              <option value="">👤 Wie ben jij?</option>
              {participants.map(p => <option key={p.id} value={p.name}>{p.name}</option>)}
            </select>

            {event.dates.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '20px', color: '#666' }}>Nog geen datums. Voeg er een toe!</div>
            ) : (
              <div style={{ overflowX: 'auto', marginBottom: '10px' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '11px' }}>
                  <thead>
                    <tr style={{ background: '#1e5799', color: 'white' }}>
                      <th style={{ padding: '6px', textAlign: 'left', borderRadius: '6px 0 0 0', position: 'sticky', left: 0, background: '#1e5799' }}>Datum</th>
                      {orderedParticipants.map((p, i) => (
                        <th key={p.id} style={{ padding: '4px 2px', textAlign: 'center', fontWeight: p.name === selectedMember ? '700' : '500', background: p.name === selectedMember ? '#2a6db5' : '#1e5799', minWidth: '40px' }}>{p.name.slice(0, 3)}</th>
                      ))}
                      <th style={{ padding: '4px 6px', textAlign: 'center', borderRadius: '0 6px 0 0', minWidth: '45px' }}>%</th>
                    </tr>
                  </thead>
                  <tbody>
                    {event.dates.map((d, ri) => {
                      const pct = calcPct(d.id);
                      const best = event.dates.every(x => calcPct(x.id) <= pct) && pct > 0;
                      return (
                        <tr key={d.id} style={{ background: best ? 'rgba(46,125,50,0.08)' : ri % 2 ? '#f8fafc' : 'white' }}>
                          <td style={{ padding: '5px 6px', borderBottom: '1px solid #eee', fontWeight: '500', color: '#1e5799', whiteSpace: 'nowrap', position: 'sticky', left: 0, background: best ? 'rgba(46,125,50,0.08)' : ri % 2 ? '#f8fafc' : 'white' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                              {best && <span>⭐</span>}{d.label}
                              <button onClick={() => setModal({ type: 'deleteDate', id: d.id, label: d.label })} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: '#999', cursor: 'pointer', fontSize: '10px', padding: '2px' }}>✕</button>
                            </div>
                          </td>
                          {orderedParticipants.map(p => {
                            const vote = event.responses?.[p.id]?.[d.id];
                            const isMe = p.name === selectedMember;
                            return (
                              <td key={p.id} style={{ padding: '3px 1px', borderBottom: '1px solid #eee', textAlign: 'center', background: isMe ? 'rgba(30,87,153,0.06)' : undefined }}>
                                {isMe ? (
                                  <div style={{ display: 'flex', gap: '1px', justifyContent: 'center' }}>
                                    {['ja', 'misschien', 'nee'].map(v => (
                                      <button key={v} onClick={() => handleVote(p.id, d.id, v)} style={{ width: '20px', height: '20px', borderRadius: '4px', fontSize: '10px', fontWeight: 'bold', cursor: 'pointer', border: vote === v ? 'none' : '1px solid #ddd', background: vote === v ? getColor(v) : 'white', color: vote === v ? 'white' : getColor(v) }}>{getIcon(v)}</button>
                                    ))}
                                  </div>
                                ) : (
                                  <span style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', width: '20px', height: '20px', borderRadius: '4px', background: vote ? `${getColor(vote)}18` : '#f5f5f5', color: getColor(vote), fontWeight: 'bold', fontSize: '11px' }}>{getIcon(vote)}</span>
                                )}
                              </td>
                            );
                          })}
                          <td style={{ padding: '4px', borderBottom: '1px solid #eee', textAlign: 'center' }}>
                            <div style={{ fontSize: '12px', fontWeight: '700', color: pct >= 50 ? '#2e7d32' : pct >= 25 ? '#f9a825' : '#999' }}>{pct}%</div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}

            {/* Legend */}
            <div style={{ display: 'flex', gap: '10px', justifyContent: 'center', padding: '6px', background: '#f8fafc', borderRadius: '6px', marginBottom: '10px', fontSize: '10px' }}>
              <span><span style={{ color: '#2e7d32', fontWeight: 'bold' }}>✓</span> Voorkeur</span>
              <span><span style={{ color: '#f9a825', fontWeight: 'bold' }}>?</span> Misschien</span>
              <span><span style={{ color: '#c62828', fontWeight: 'bold' }}>✗</span> Niet</span>
            </div>

            {/* Add date */}
            <div style={{ display: 'flex', gap: '6px', marginBottom: '10px' }}>
              <input type="date" value={newDate} onChange={(e) => setNewDate(e.target.value)} style={{ flex: 1, padding: '8px', borderRadius: '6px', border: '1px solid #1e5799', fontSize: '13px' }}/>
              <button onClick={addDate} disabled={!newDate} style={{ padding: '8px 14px', background: newDate ? '#1e5799' : '#ccc', color: 'white', border: 'none', borderRadius: '6px', fontSize: '12px', fontWeight: '600', cursor: newDate ? 'pointer' : 'not-allowed' }}>+ Datum</button>
            </div>

            {/* Comments */}
            <div style={{ borderTop: '1px solid #eee', paddingTop: '10px' }}>
              <div style={{ fontSize: '12px', fontWeight: '600', color: '#1e5799', marginBottom: '6px' }}>💬 Opmerkingen</div>
              {event.comments?.length > 0 && (
                <div style={{ marginBottom: '8px' }}>
                  {event.comments.map(c => (
                    <div key={c.id} style={{ padding: '6px 8px', background: '#f8fafc', borderRadius: '6px', borderLeft: '3px solid #1e5799', marginBottom: '4px', fontSize: '11px' }}>
                      <strong style={{ color: '#1e5799' }}>{c.author}</strong> <span style={{ color: '#999', fontSize: '10px' }}>{c.time}</span>
                      <div style={{ color: '#333', marginTop: '2px' }}>{c.text}</div>
                    </div>
                  ))}
                </div>
              )}
              <div style={{ display: 'flex', gap: '6px' }}>
                <input value={newComment} onChange={(e) => setNewComment(e.target.value)} placeholder={selectedMember ? "Opmerking..." : "Selecteer eerst je naam"} disabled={!selectedMember} style={{ flex: 1, padding: '8px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '12px' }}/>
                <button onClick={addComment} disabled={!newComment || !selectedMember} style={{ padding: '8px 12px', background: (newComment && selectedMember) ? '#1e5799' : '#ccc', color: 'white', border: 'none', borderRadius: '6px', fontSize: '12px', cursor: (newComment && selectedMember) ? 'pointer' : 'not-allowed' }}>+</button>
              </div>
            </div>
          </div>
        )}

        {/* EVENTS VIEW */}
        {view === 'events' && (
          <div style={{ background: 'white', borderRadius: '10px', padding: '12px', boxShadow: '0 2px 8px rgba(30,87,153,0.1)' }}>
            <div style={{ fontSize: '14px', fontWeight: '600', color: '#1e5799', marginBottom: '12px' }}>📅 Evenementen</div>
            
            {data.events.map(e => (
              <div key={e.id} onClick={() => { setActiveEventId(e.id); setView('poll'); }} style={{ padding: '10px 12px', background: e.id === activeEventId ? 'rgba(30,87,153,0.1)' : '#f8fafc', borderRadius: '8px', marginBottom: '8px', cursor: 'pointer', border: e.id === activeEventId ? '2px solid #1e5799' : '1px solid #eee' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontWeight: '600', color: '#1e5799', fontSize: '13px' }}>{e.title}</div>
                    <div style={{ fontSize: '11px', color: '#666' }}>🕐 {e.time} • {e.dates.length} datums • {e.participants.length} deelnemers</div>
                  </div>
                  {data.events.length > 1 && (
                    <button onClick={(ev) => { ev.stopPropagation(); setModal({ type: 'deleteEvent', id: e.id, title: e.title }); }} style={{ background: 'none', border: 'none', color: '#c62828', cursor: 'pointer', fontSize: '14px' }}>🗑</button>
                  )}
                </div>
              </div>
            ))}

            <div style={{ borderTop: '1px solid #eee', paddingTop: '12px', marginTop: '12px' }}>
              <div style={{ fontSize: '12px', fontWeight: '600', color: '#1e5799', marginBottom: '8px' }}>➕ Nieuw evenement</div>
              <input value={newEventTitle} onChange={(e) => setNewEventTitle(e.target.value)} placeholder="Titel (bijv. Vergadering 2 - 2026)" style={{ width: '100%', padding: '8px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '13px', marginBottom: '8px', boxSizing: 'border-box' }}/>
              <div style={{ display: 'flex', gap: '6px' }}>
                <input value={newEventTime} onChange={(e) => setNewEventTime(e.target.value)} placeholder="Tijd" style={{ flex: 1, padding: '8px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '13px' }}/>
                <button onClick={createEvent} disabled={!newEventTitle} style={{ padding: '8px 16px', background: newEventTitle ? '#1e5799' : '#ccc', color: 'white', border: 'none', borderRadius: '6px', fontSize: '12px', fontWeight: '600', cursor: newEventTitle ? 'pointer' : 'not-allowed' }}>Aanmaken</button>
              </div>
            </div>
          </div>
        )}

        {/* PARTICIPANTS VIEW */}
        {view === 'participants' && (
          <div style={{ background: 'white', borderRadius: '10px', padding: '12px', boxShadow: '0 2px 8px rgba(30,87,153,0.1)' }}>
            <div style={{ fontSize: '14px', fontWeight: '600', color: '#1e5799', marginBottom: '12px' }}>👥 Deelnemers - {event.title}</div>
            
            {participants.map(p => {
              const hasResponded = Object.keys(event.responses?.[p.id] || {}).length > 0;
              return (
                <div key={p.id} style={{ padding: '10px 12px', background: '#f8fafc', borderRadius: '8px', marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: hasResponded ? '#2e7d32' : '#f9a825', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 'bold' }}>{p.name.slice(0, 2)}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: '600', color: '#333', fontSize: '13px' }}>{p.name}</div>
                    <div style={{ fontSize: '11px', color: '#666' }}>{p.email || 'Geen email'} • {hasResponded ? '✅ Gereageerd' : '⏳ Nog niet'}</div>
                  </div>
                  {p.email && (
                    <button onClick={() => sendInviteEmail(p)} style={{ padding: '6px 10px', background: '#1e5799', color: 'white', border: 'none', borderRadius: '4px', fontSize: '10px', cursor: 'pointer' }}>📧</button>
                  )}
                  <button onClick={() => setModal({ type: 'deleteParticipant', id: p.id, name: p.name })} style={{ background: 'none', border: 'none', color: '#c62828', cursor: 'pointer', fontSize: '14px' }}>✕</button>
                </div>
              );
            })}

            <div style={{ borderTop: '1px solid #eee', paddingTop: '12px', marginTop: '12px' }}>
              <div style={{ fontSize: '12px', fontWeight: '600', color: '#1e5799', marginBottom: '8px' }}>➕ Deelnemer toevoegen</div>
              <input value={newParticipant.name} onChange={(e) => setNewParticipant({ ...newParticipant, name: e.target.value })} placeholder="Naam *" style={{ width: '100%', padding: '8px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '13px', marginBottom: '6px', boxSizing: 'border-box' }}/>
              <div style={{ display: 'flex', gap: '6px' }}>
                <input value={newParticipant.email} onChange={(e) => setNewParticipant({ ...newParticipant, email: e.target.value })} placeholder="Email (optioneel)" style={{ flex: 1, padding: '8px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '13px' }}/>
                <button onClick={addParticipant} disabled={!newParticipant.name} style={{ padding: '8px 16px', background: newParticipant.name ? '#1e5799' : '#ccc', color: 'white', border: 'none', borderRadius: '6px', fontSize: '12px', fontWeight: '600', cursor: newParticipant.name ? 'pointer' : 'not-allowed' }}>+</button>
              </div>
            </div>
          </div>
        )}

        {/* LOCATIONS VIEW */}
        {view === 'locations' && (
          <div style={{ background: 'white', borderRadius: '10px', padding: '12px', boxShadow: '0 2px 8px rgba(30,87,153,0.1)' }}>
            <div style={{ fontSize: '14px', fontWeight: '600', color: '#1e5799', marginBottom: '12px' }}>📍 Locaties - {event.title}</div>
            
            {(!event.locations || event.locations.length === 0) ? (
              <div style={{ textAlign: 'center', padding: '20px', color: '#666', fontSize: '13px' }}>Nog geen locaties voorgesteld</div>
            ) : (
              event.locations.map(loc => {
                const myId = participants.find(p => p.name === selectedMember)?.id;
                const hasVoted = loc.votes?.includes(myId);
                return (
                  <div key={loc.id} style={{ padding: '10px 12px', background: '#f8fafc', borderRadius: '8px', marginBottom: '6px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontWeight: '600', color: '#1e5799', fontSize: '13px' }}>{loc.name}</div>
                        {loc.address && <div style={{ fontSize: '11px', color: '#666' }}>📍 {loc.address}</div>}
                        <div style={{ fontSize: '10px', color: '#999', marginTop: '2px' }}>Voorgesteld door {loc.proposedBy || 'onbekend'}</div>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <button onClick={() => voteLocation(loc.id)} disabled={!selectedMember} style={{ padding: '6px 12px', background: hasVoted ? '#2e7d32' : '#eee', color: hasVoted ? 'white' : '#333', border: 'none', borderRadius: '4px', fontSize: '11px', cursor: selectedMember ? 'pointer' : 'not-allowed', fontWeight: '600' }}>👍 {loc.votes?.length || 0}</button>
                        <button onClick={() => setModal({ type: 'deleteLocation', id: loc.id, name: loc.name })} style={{ background: 'none', border: 'none', color: '#c62828', cursor: 'pointer' }}>✕</button>
                      </div>
                    </div>
                  </div>
                );
              })
            )}

            <div style={{ borderTop: '1px solid #eee', paddingTop: '12px', marginTop: '12px' }}>
              <div style={{ fontSize: '12px', fontWeight: '600', color: '#1e5799', marginBottom: '8px' }}>➕ Locatie voorstellen</div>
              <input value={newLocation.name} onChange={(e) => setNewLocation({ ...newLocation, name: e.target.value })} placeholder="Naam locatie *" style={{ width: '100%', padding: '8px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '13px', marginBottom: '6px', boxSizing: 'border-box' }}/>
              <input value={newLocation.address} onChange={(e) => setNewLocation({ ...newLocation, address: e.target.value })} placeholder="Adres (optioneel)" style={{ width: '100%', padding: '8px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '13px', marginBottom: '6px', boxSizing: 'border-box' }}/>
              <div style={{ display: 'flex', gap: '6px' }}>
                <select value={newLocation.proposedBy} onChange={(e) => setNewLocation({ ...newLocation, proposedBy: e.target.value })} style={{ flex: 1, padding: '8px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '13px' }}>
                  <option value="">Wie stelt voor?</option>
                  {participants.map(p => <option key={p.id} value={p.name}>{p.name}</option>)}
                </select>
                <button onClick={addLocation} disabled={!newLocation.name} style={{ padding: '8px 16px', background: newLocation.name ? '#1e5799' : '#ccc', color: 'white', border: 'none', borderRadius: '6px', fontSize: '12px', fontWeight: '600', cursor: newLocation.name ? 'pointer' : 'not-allowed' }}>+</button>
              </div>
            </div>
          </div>
        )}

        {/* SUMMARY VIEW */}
        {view === 'summary' && (
          <div style={{ background: 'white', borderRadius: '10px', padding: '12px', boxShadow: '0 2px 8px rgba(30,87,153,0.1)' }}>
            <div style={{ fontSize: '14px', fontWeight: '600', color: '#1e5799', marginBottom: '12px' }}>📋 Samenvatting delen</div>
            
            <div style={{ background: '#f8fafc', borderRadius: '8px', padding: '12px', marginBottom: '12px', fontFamily: 'monospace', fontSize: '11px', whiteSpace: 'pre-wrap', color: '#333', maxHeight: '300px', overflow: 'auto' }}>
              {generateSummary()}
            </div>

            <button onClick={copySummary} style={{ width: '100%', padding: '12px', background: copied ? '#2e7d32' : '#1e5799', color: 'white', border: 'none', borderRadius: '8px', fontSize: '14px', fontWeight: '600', cursor: 'pointer', marginBottom: '8px' }}>
              {copied ? '✅ Gekopieerd!' : '📋 Kopieer voor WhatsApp / Email'}
            </button>

            <div style={{ display: 'flex', gap: '6px' }}>
              <a href={`https://wa.me/?text=${encodeURIComponent(generateSummary())}`} target="_blank" rel="noreferrer" style={{ flex: 1, padding: '10px', background: '#25D366', color: 'white', border: 'none', borderRadius: '6px', fontSize: '12px', fontWeight: '600', textAlign: 'center', textDecoration: 'none' }}>WhatsApp</a>
              <a href={`mailto:?subject=${encodeURIComponent(event.title + ' - Tussenstand')}&body=${encodeURIComponent(generateSummary())}`} style={{ flex: 1, padding: '10px', background: '#666', color: 'white', border: 'none', borderRadius: '6px', fontSize: '12px', fontWeight: '600', textAlign: 'center', textDecoration: 'none' }}>Email</a>
            </div>
          </div>
        )}

        {/* Footer */}
        <div style={{ textAlign: 'center', padding: '16px 8px 8px', color: '#1e5799', fontSize: '11px', fontStyle: 'italic' }}>
          "Beter een goede buur dan een verre vriend"
        </div>
      </div>

      {/* Delete Confirmation Modal */}
      {modal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '20px' }}>
          <div style={{ background: 'white', padding: '20px', borderRadius: '12px', maxWidth: '300px', width: '100%', textAlign: 'center', boxShadow: '0 8px 32px rgba(0,0,0,0.2)' }}>
            <div style={{ fontSize: '32px', marginBottom: '8px' }}>⚠️</div>
            <h3 style={{ margin: '0 0 8px', color: '#1e5799', fontSize: '16px' }}>Weet je het zeker?</h3>
            <p style={{ margin: '0 0 16px', color: '#666', fontSize: '13px' }}>
              {modal.type === 'deleteDate' && `"${modal.label}" en alle stemmen worden verwijderd.`}
              {modal.type === 'deleteEvent' && `"${modal.title}" en alle data worden verwijderd.`}
              {modal.type === 'deleteParticipant' && `${modal.name} wordt verwijderd uit dit evenement.`}
              {modal.type === 'deleteLocation' && `"${modal.name}" wordt verwijderd.`}
            </p>
            <div style={{ display: 'flex', gap: '8px', justifyContent: 'center' }}>
              <button onClick={() => setModal(null)} style={{ padding: '10px 20px', background: '#f0f0f0', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: '500', fontSize: '13px' }}>Annuleren</button>
              <button onClick={() => {
                if (modal.type === 'deleteDate') deleteDate(modal.id);
                if (modal.type === 'deleteEvent') deleteEvent(modal.id);
                if (modal.type === 'deleteParticipant') removeParticipant(modal.id);
                if (modal.type === 'deleteLocation') deleteLocation(modal.id);
              }} style={{ padding: '10px 20px', background: '#c62828', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: '500', fontSize: '13px' }}>Verwijderen</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
