////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import UIKit
import RxSwift

//MARK: search
extension SpeakersViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    func setupSearchBar() {
        //search bar
        searchController.searchBar.delegate = self

        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.center = CGPoint(
            x: navigationController!.navigationBar.frame.midX + 4,
            y: 20)
        
        //search controller is the worst
        let iOSVersion = NSString(string: UIDevice.current.systemVersion).doubleValue
        if iOSVersion < 9.0 {
            //position the bar on iOS8
            searchController.searchBar.center = CGPoint(
                x: navigationController!.navigationBar.frame.minX + 4,
                y: 20)
        }
    }
    
    func toggleSearchBarVisibility(_ visible: Bool) {
        if visible {
            navigationController!.navigationBar.addSubview(
                searchController.searchBar
            )
            searchController.searchBar.barTintColor = .white
        } else {
            searchController.searchBar.removeFromSuperview()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBarBtnCancel.onNext()
    }
    
    func fadeInSearchBar(_ visible: Bool) {
        let (from, to) = visible ? (0.0, 1.0) : (1.0, 0.0)
        
        searchController.searchBar.alpha = CGFloat(from)
        searchController.searchBar.setNeedsDisplay()
        
        UIView.animate(withDuration: 0.33, delay: 0, options: [], animations: {
            self.searchController.searchBar.alpha = CGFloat(to)
            }, completion: nil)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        //placeholder
    }

    internal func bindingsSearchBar() -> [Disposable] {
        // is search bar currently active
        let searchBarActive = Observable<Bool>.merge([btnSearch.rx.tap.replaceWith(true), searchBarBtnCancel.replaceWith(false)])
            .startWith(false)
            .shareReplay(1)

        return [
            //bind search bar
            searchController.searchBar.rx.text.orEmpty
                .bind(to: viewModel.searchTerm),

            //present/dismiss search bar
            searchBarActive.subscribe(onNext: toggleSearchBarVisibility),

            //show/hide the bar
            Observable.combineLatest(searchBarActive, active.asObservable(), resultSelector: { (a, b) -> Bool in
                return a && b
            })
            .bind(to: searchController.searchBar.rx.visible),

            //show/hide nav buttons
            searchBarActive
                .subscribe(onNext: {[unowned self] hideButtons in
                    self.navigationItem.leftBarButtonItem = hideButtons ? nil : self.btnSearch
                    self.navigationItem.rightBarButtonItem = hideButtons ? nil : self.btnFavorites
                }),

            //hide keyboard
            active.asObservable().filterOut(true)
                .subscribe(onNext: { [unowned self]_ in
                    self.view.endEditing(true)
                }),

            searchBarActive.bind(to: searchController.searchBar.rx.isFirstResponder),
            searchBarActive.subscribe(onNext: fadeInSearchBar),
            searchBarActive.filterOut(true).replaceWith("").bind(to: viewModel.searchTerm)
        ]
    }
}