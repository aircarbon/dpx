import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/intro">
            Get Started
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title}`}
      description="Smart Contracts for ACR Governance & Carbon Credit Tokenization">
      <HomepageHeader />
      <main>
        <section className={styles.features}>
          <div className="container">
            <div className="row">
              <div className="col col--6">
                <h3>ACR Governance Token</h3>
                <p>
                  Upgradeable ERC-20 governance token with on-chain voting capabilities.
                  Deployed on Avalanche C-chain.
                </p>
              </div>
              <div className="col col--6">
                <h3>DPX Platform</h3>
                <p>
                  Decentralized platform for tokenizing future carbon credits.
                  Enable project developers to raise capital for carbon credit projects.
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
