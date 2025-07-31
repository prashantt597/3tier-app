import { render, screen } from '@testing-library/react';
import App from './App';

describe('App Component', () => {
  it('renders welcome banner', () => {
    render(<App />);
    expect(screen.getByText(/welcome to DevOps Shack/i)).toBeInTheDocument();
  });
});