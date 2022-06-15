<!doctype html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://thymeleaf.org">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Project Serum market data">
    <title>Openserum Market Data</title>
    <link rel="shortcut icon" type="image/png" href="static/serum-srm-logo.png"/>

    <!-- jquery & chartjs -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"
            integrity="sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.8.0/chart.min.js"
            integrity="sha512-sW/w8s4RWTdFFSduOTGtk4isV1+190E/GghVffMA9XczdJ2MDzSzLEubKAs5h0wzgSJOQTRYyaz73L3d6RtJSg=="
            crossorigin="anonymous" referrerpolicy="no-referrer"></script>


    <!-- CSS only -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.0-beta1/dist/css/bootstrap.min.css" rel="stylesheet"
          integrity="sha384-0evHe/X+R7YkIZDRvuzKMRqM+OrBnVFBL6DOitfPri4tjfHxaWutUpFmBp4vmVor" crossorigin="anonymous">

    <style>
        .chart-container {
            height: 400px;
            width: 100%;
        }

        .nav-scroller .nav {
            display: flex;
            flex-wrap: nowrap;
            padding-bottom: 1rem;
            margin-top: -1px;
            overflow-x: auto;
            text-align: center;
            white-space: nowrap;
            -webkit-overflow-scrolling: touch;
        }

        /* sticky footer */
        html {
            position: relative;
            min-height: 100%;
        }

        img.img-icon {
            margin: 0 !important;
            display: inherit !important;
            height: 18px;
            width: 18px
        }

        * {
            box-sizing: border-box;
        }

        .row {
            display: flex;
            margin-left: -5px;
            margin-right: -5px;
        }

        .column {
            flex: 50%;
            padding: 5px;
        }

    </style>
    <link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet"/>
    <script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>

    <script>
        function formatToken(token) {
            // only load top 100 icons
            if (!token.id || token.element.dataset.rank > 100) {
                return token.text;
            }
            return $(
                '<span><img src="' + token.element.dataset.icon + '" class="img-icon" /> ' + token.text + '</span>'
            );
        };

        $(document).ready(function () {
            var options = $("#tokenSelect option");                    // Collect options
            options.detach().sort(function (a, b) {               // Detach from select, then Sort
                var at = $(a).data("rank");
                var bt = $(b).data("rank");
                return (at > bt) ? 1 : ((at < bt) ? -1 : 0);            // Tell the sort function how to order
            });
            options.appendTo("#tokenSelect");                          // Re-attach to select
            $("#tokenSelect").val($("#tokenSelect option:first").val());
            $("#tokenSelect").show();

            $('#tokenSelect').select2({
                templateResult: formatToken,
                templateSelection: formatToken
            });
        });
    </script>
</head>
<body class="bg-light">
<div class="container">
    <header class="d-flex flex-wrap justify-content-center py-3 mb-4 border-bottom">
        <a href="#" class="d-flex align-items-center mb-3 mb-md-0 me-md-auto text-dark text-decoration-none">
            <span class="fs-4"><img src="static/serum-srm-logo.png" width="32" height="32"
                                    style="margin-right: 0.5rem!important;">Openserum Market Data</span>
        </a>

        <ul class="nav nav-pills">
            <li class="nav-item"><a href="#" class="nav-link active" aria-current="page">Home</a></li>
        </ul>
    </header>
</div>
<main class="container">
    <div class="p-5 rounded" style="padding-top: 0px!important;">
        <div class="row">
            <div class="col-sm-4">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Tokens</h5>
                        <p class="card-text">
                            <select class="form-control" id="tokenSelect" style="display: none">
                                <option th:each="token : ${tokens.values()}"
                                        th:value="${token.address}"
                                        th:attr="data-icon=${token.logoURI},data-rank=${marketRankManager.getMarketRankOfToken(token.address)}"
                                        th:text="${token.symbol} + ' (' + ${token.name} + ') (' + ${token.address} + ')'">
                                </option>
                            </select>
                        </p>
                        <hr>
                        Popular: <a
                            href="#" onClick="loadMarkets('9n4nbM75f5Ui33ZbPYXn59EwSgE8CGsHtAeTH5YFeJ9E');">BTC</a> - <a
                            href="#" onClick="loadMarkets('7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs');">ETH</a> - <a
                            href="#" onClick="loadMarkets('So11111111111111111111111111111111111111112');">SOL</a> - <a
                            href="#" onClick="loadMarkets('MangoCzJ36AjZyKwVj3VnYU4GTonjfVEnJmvvWaxLac');">MNGO</a> - <a
                            href="#" onClick="loadMarkets('orcaEKTdK7LKz57vaAYr9QeNsVEPfiu6QeMU1kektZE');">ORCA</a>
                        <hr>
                        <input type="button" class="btn btn-primary" value="Search for Markets" id="searchForMarkets"
                               style="width: 100%">
                    </div>
                </div>
                <!-- markets card -->
                <p>
                <div class="card overflow-auto">
                    <div class="card-body">
                        <h5 class="card-title">Markets</h5>
                        <hr>
                        <ul id="marketList" style="height: 100px; overflow: auto; list-style: none; padding-left: 5px">
                        </ul>
                    </div>
                </div>
            </div>
            <div class="col-sm-8">
                <div class="card">
                    <div class="card-body">
                        <h5 id="priceChartTitle" class="card-title">Price Chart</h5>
                        <div class="chart-container">
                            <canvas id="myChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <p>
        <div class="row">
            <div class="card col-sm-8">
                <div class="card-body">
                    <div style="font-size: 1.25rem; font-weight: 500; display: inline" id="orderBookHeader">Order Book:</div>
                    <hr>
                    <div class="row">
                        <div class="column">
                            <table id="bidsTable" class="table table-striped table-hover table-bordered"
                                   style="width: 100%">
                                <thead>
                                <tr>
                                    <th scope="col">Price</th>
                                    <th scope="col">Quantity</th>
                                    <th scope="col">Owner</th>
                                </tr>
                                </thead>
                                <tbody>
                                </tbody>
                            </table>
                        </div>
                        <div class="column">
                            <table id="asksTable" class="table table-striped table-hover table-bordered"
                                   style="width: 100%">
                                <thead>
                                <tr>
                                    <th scope="col">Price</th>
                                    <th scope="col">Quantity</th>
                                    <th scope="col">Owner</th>
                                </tr>
                                </thead>
                                <tbody>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
            <div class="card col-sm-4">
                <div class="card-body">
                    <h5 id="tradeHistoryTitle" class="card-title">Trade History</h5>
                    <hr>
                    <table id="tradeHistoryTable" class="table table-hover table-bordered" style="width: 100%">
                        <thead>
                        <tr>
                            <th scope="col">Price</th>
                            <th scope="col">Quantity</th>
                            <th scope="col">Owner</th>
                        </tr>
                        </thead>
                        <tbody>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</main>
<!-- JavaScript Bundle with Popper -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.0-beta1/dist/js/bootstrap.bundle.min.js"
        integrity="sha384-pprn3073KE6tl6bjs2QrFaJGz5/SUsLqktiwsUTF55Jfv3qYSDhgCecCxMW52nD2"
        crossorigin="anonymous"></script>
<script>
    var activeMarketId;
    const ctx = document.getElementById('myChart').getContext('2d');
    const myChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Price',
                data: [],
                fill: false,
                borderColor: 'rgb(41,98,255)',
                tension: 0.1
            }]
        },
        options: {
            scales: {
                y: {
                    beginAtZero: false
                }
            },
            responsive: true,
            maintainAspectRatio: false
        }
    });

    function addData(label, data) {
        myChart.data.labels.push(label);
        myChart.data.datasets.forEach((dataset) => {
            dataset.data.push(data);
        });
        //myChart.update();
    }

    $('#searchForMarkets').click(function () {
        var baseMint = $('#tokenSelect').val();
        loadMarkets(baseMint);
    });

    function loadMarkets(tokenId) {
        let apiUrl = "/api/serum/token/" + tokenId;
        $.get(apiUrl, function (data) {
            $("#marketList").empty();
            $.each(data, function (k, v) {
                $("#marketList").append(
                    "<li>" +
                    "<img src=" + v.baseLogo + " class=\"img-icon\" style=\"float: left\"/> " +
                    "<a href=\"#\" onClick=\"setMarket('" + v.id + "');\">" +
                    v.baseSymbol + " / " + v.quoteSymbol + " / " + v.id.substring(0, 3) + ".." + v.id.substring(v.id.length - 3)
                    + "</a></li>"
                );
            })
        });
    }

    function setMarket(marketId) {
        activeMarketId = marketId; // starts order book loop

        // update trade history
        loadTradeHistory(marketId);
    }

    function loadTradeHistory(marketId) {
        let apiUrl = "/api/serum/market/" + marketId + "/tradeHistory";
        $.get(apiUrl, function (data) {
            $('#tradeHistoryTable tbody').empty();

            // reset chart
            myChart.data = {
                labels: [],
                datasets: [{
                    label: 'Price',
                    data: [],
                    fill: false,
                    borderColor: 'rgb(41,98,255)',
                    tension: 0.1
                }]
            };
            myChart.update();

            $.each(data, function (k, v) {
                if (!v.flags.maker) {
                    $("#tradeHistoryTable tbody").append(
                        "<tr class='" + (v.flags.bid ? "table-success" : "table-danger") + "'>" +
                        "<td>" + v.price + "</td>" +
                        "<td style=\"text-align: right\">" + v.quantity + "</td>" +
                        "<td>" + (v.owner.toString().length > 32 ? v.owner.substring(0, 3) + ".." + v.owner.substring(v.owner.toString().length - 3) : v.owner) + "</td>" +
                        "</tr>"
                    );
                }
                addData(k, v.price);
            })

            myChart.data.datasets.forEach((dataset) => {
                dataset.data.reverse();
            });
            myChart.update();
        });
    }

    function loadMarketDetail() {
        let apiUrl = "/api/serum/market/" + activeMarketId;
        $.get({url: apiUrl, cache: false})
        .done(function (data) {
            $("#orderBookHeader").html("Order Book: " +
                "<img id=\"baseLogo\" class=\"img-icon\"> " +
                "<span id=\"baseName\"></span> / " +
                "<img id=\"quoteLogo\" class=\"img-icon\"> " +
                "<span id=\"quoteName\"></span> " +
                "<span id=\"ownerName\"></span>"
            );
            $("#baseName").text(data.baseSymbol);
            $("#priceChartTitle").text(data.baseSymbol + "/" + data.quoteSymbol + " Price Chart")
            $("#tradeHistoryTitle").text(data.baseSymbol + " Trade History")
            $("#quoteName").text(data.quoteSymbol);
            $("#ownerName").text("(" + data.id.substring(0, 3) + ".." + data.id.substring(data.id.toString().length - 3) + ")");
            $("#baseLogo").attr("src", data.baseLogo);
            $("#quoteLogo").attr("src", data.quoteLogo);


            // bids
            $('#bidsTable tbody').empty();
            $.each(data.bids, function (k, v) {
                $("#bidsTable tbody").append(
                    "<tr>" +
                    "<td>" + v.price + "</td>" +
                    "<td style=\"text-align: right\">" + v.quantity + "</td>" +
                    "<td>" + (v.owner.toString().length > 32 ? v.owner.substring(0, 3) + ".." + v.owner.substring(v.owner.toString().length - 3) : v.owner) + "</td>" +
                    "</tr>"
                );
            })

            // asks
            $('#asksTable tbody').empty();
            $.each(data.asks, function (k, v) {
                $("#asksTable tbody").append(
                    "<tr>" +
                    "<td>" + v.price + "</td>" +
                    "<td style=\"text-align: right\">" + v.quantity + "</td>" +
                    "<td>" + (v.owner.toString().length > 32 ? v.owner.substring(0, 3) + ".." + v.owner.substring(v.owner.toString().length - 3) : v.owner) + "</td>" +
                    "</tr>"
                );
            })
        });
    }

    function updateOrderBookLoop() {
        if (activeMarketId) {
            loadMarketDetail();
        }
    }

    setInterval(updateOrderBookLoop, 1200);
</script>
</body>
</html>