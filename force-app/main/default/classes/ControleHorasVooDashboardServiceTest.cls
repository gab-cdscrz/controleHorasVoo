@isTest
private class ControleHorasVooDashboardServiceTest {
    @isTest
    static void shouldAggregateFlightHoursAndExcludeRefueling() {
        empregado__c pilot = TestDataStatic.empregadoPiloto;
        Aeronave__c aircraft = TestDataStatic.aeronaveteste;
        Date referenceDate = Date.today();

        insert new List<Controle_Horas_Voo__c>{
            createFlight(aircraft.Id, pilot.Id, referenceDate, 'TR', 1.5),
            createFlight(aircraft.Id, pilot.Id, referenceDate, 'TT', 0.5),
            createFlight(aircraft.Id, pilot.Id, referenceDate, 'AB', 0),
            createFlight(
                aircraft.Id,
                pilot.Id,
                referenceDate.addMonths(-1),
                'SA',
                8
            )
        };

        List<ControleHorasVooDashboardService.AircraftReference> aircraftList =
            new List<ControleHorasVooDashboardService.AircraftReference>{
                new ControleHorasVooDashboardService.AircraftReference(
                    aircraft.Id,
                    aircraft.Name
                )
            };
        Date startDate = Date.newInstance(
            referenceDate.year(),
            referenceDate.month(),
            1
        );

        Test.startTest();
        ControleHorasVooDashboardService.DashboardResult result =
            ControleHorasVooDashboardService.build(
                aircraftList,
                startDate,
                startDate.addMonths(1)
            );
        Test.stopTest();

        Assert.areEqual(1, result.aircraft.size(), 'One aircraft is expected.');
        Assert.areEqual(2, result.totalFlights, 'AB must not count as a flight.');
        Assert.areEqual(
            Decimal.valueOf('2.0'),
            result.totalHours,
            'Only hours from the requested month should be aggregated.'
        );
        Assert.areEqual(
            'Translado',
            ControleHorasVooDashboardService.getFlightTypeLabel('TR'),
            'TR must always be displayed as Translado.'
        );
        Assert.areEqual(
            'Tentativa',
            ControleHorasVooDashboardService.getFlightTypeLabel('TT'),
            'TT must always be displayed as Tentativa.'
        );
    }

    @isTest
    static void shouldReturnEmptyDashboardWhenAircraftListIsEmpty() {
        Test.startTest();
        ControleHorasVooDashboardService.DashboardResult result =
            ControleHorasVooDashboardService.build(
                new List<ControleHorasVooDashboardService.AircraftReference>(),
                Date.today(),
                Date.today().addMonths(1)
            );
        Test.stopTest();

        Assert.isTrue(
            result.aircraft.isEmpty(),
            'No aircraft cards should be returned for an empty input.'
        );
        Assert.areEqual(0, result.totalFlights, 'No flights should be counted.');
        Assert.areEqual(
            Decimal.valueOf('0'),
            result.totalHours,
            'No flight hours should be counted.'
        );
    }

    private static Controle_Horas_Voo__c createFlight(
        Id aircraftId,
        Id pilotId,
        Date flightDate,
        String flightType,
        Decimal hours
    ) {
        return new Controle_Horas_Voo__c(
            Aeronave__c = aircraftId,
            Piloto__c = pilotId,
            Data_do_Voo__c = flightDate,
            Tipo__c = flightType,
            Horas_Voo__c = hours,
            TOT__c = hours
        );
    }
}