interface HeaderProps {}

export default function Header({}: HeaderProps) {
  return (
    <header style={{
      background: 'linear-gradient(135deg, var(--card-bg) 0%, #0f1419 100%)',
      borderBottom: '2px solid var(--primary-color)',
      padding: '20px 0',
      marginBottom: '40px',
    }}>
      <div className="container" style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <span style={{ fontSize: '32px' }}>₿</span>
          <div>
            <h1 style={{ fontSize: '24px', margin: 0 }}>Bitcoin Vault</h1>
            <p style={{ fontSize: '12px', color: 'var(--text-secondary)', margin: 0 }}>
              Stellar Testnet
            </p>
          </div>
        </div>
        <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
          <a
            href="https://stellar.expert/explorer/testnet/contract/CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA"
            target="_blank"
            rel="noopener noreferrer"
            className="btn btn-outline"
            style={{ fontSize: '14px', padding: '8px 16px' }}
          >
            View Contract
          </a>
        </div>
      </div>
    </header>
  );
}
