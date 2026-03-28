require "rails_helper"

RSpec.describe Recsports::Client do
  let(:credential) do
    RecsportsCredential.new(
      form_url: "https://sportclubs.example.com/clubs/ultimate",
      username: "ethan",
      password: "secret"
    )
  end

  let(:event_index_html) do
    <<~HTML
      <html>
        <body>
          <table>
            <tbody>
              <tr>
                <td>Monday Practice</td>
                <td><a href="/events/123">View</a></td>
              </tr>
            </tbody>
          </table>
        </body>
      </html>
    HTML
  end

  let(:event_page_html) do
    <<~HTML
      <html>
        <body>
          <h1>Ultimate Frisbee Sports Club</h1>
          <div>Event Name: Monday Practice Event Type: Practice Event Venue: Field 7 Event Date/Time: 08/25/2025 08:00pm to 08/25/2025 10:00pm Created By: Morgan Ponton (morgan.ponton@email.tamu.edu) Created At: 08/25/2025 05:46pm</div>
          <h3>Participants</h3>
          <table class="table table-striped table-bordered">
            <thead>
              <tr>
                <th>First Name</th>
                <th>Last Name</th>
                <th>UIN</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Aldrich</td>
                <td>Leow</td>
                <td>732005379</td>
              </tr>
              <tr>
                <td>Alexander</td>
                <td>Vo</td>
                <td>535009099</td>
              </tr>
            </tbody>
          </table>
        </body>
      </html>
    HTML
  end

  it "discovers event detail pages and parses participant rows" do
    client = described_class.new(credential)

    allow(client).to receive(:authenticated_response).and_return(
      body: event_index_html,
      url: "https://sportclubs.example.com/clubs/ultimate",
      code: 200
    )

    allow(client).to receive(:get).with("https://sportclubs.example.com/events/123", referer: "https://sportclubs.example.com/clubs/ultimate").and_return(
      body: event_page_html,
      url: "https://sportclubs.example.com/events/123",
      code: 200
    )

    snapshot = client.fetch_snapshot
    event = snapshot.fetch("events").first

    expect(event["title"]).to eq("Monday Practice")
    expect(event["venue"]).to eq("Field 7")
    expect(event["created_by_email"]).to eq("morgan.ponton@email.tamu.edu")
    expect(event["participants"].size).to eq(2)
    expect(event["participants"].first).to include(
      "first_name" => "Aldrich",
      "last_name" => "Leow",
      "uin" => "732005379"
    )
  end
end
